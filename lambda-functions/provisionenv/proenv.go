package provisionenv

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/30Piraten/aws-dynamicEventBuilder/logging"
	"github.com/30Piraten/aws-dynamicEventBuilder/metrics"
	"github.com/30Piraten/aws-dynamicEventBuilder/ssm"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/google/uuid"
)

// EC2Config is the configuration for the EC2 instance
type EC2Config struct {
	InstanceType string            `json:"instanceType"`
	AMI          string            `json:"ami"`
	KeyName      string            `json:"key_name"`
	SubnetID     string            `json:"subnet_id"`
	Tags         map[string]string `json:"tags"`
}

// StateEntry is the entry that represents the DynamoDB record
// for tracking EC2 instances
type StateEntry struct {
	ID          string    `json:"id"`
	Environment string    `json:"environment"`
	Region      string    `json:"region"`
	InstanceID  string    `json:"instance_id"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	ExpiresAt   time.Time `json:"expires_at"`
	TTL         int64     `json:"ttl"`
}

// HandleProvisionRequest is the handler for the provisoning
// the EC2 instance and storing the state in DynamoDB
func HandleProvisionRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	// Parse the request
	var req struct {
		Environment string    `json:"environment"`
		Region      string    `json:"region"`
		EC2         EC2Config `json:"ec2"`
		TTL         int64     `json:"ttl"`
	}

	if err := json.Unmarshal([]byte(event.Body), &req); err != nil {
		return createErrorResponse(400, "Invalid request format: ", err)
	}

	// Initialise the AWS client
	config, err := config.LoadDefaultConfig(ctx, config.WithRegion(req.Region))
	if err != nil {
		return createErrorResponse(500, "Failed to initialise AWS config: ", err)
	}

	// Generate unique ID for tracking the instance
	provisionID := uuid.New().String()

	// Create EC2  Client
	ec2Client := ec2.NewFromConfig(config)

	// Lanuch EC2 instance
	instanceID, err := lauchEC2Instance(ctx, ec2Client, req.EC2, req.Environment, req.TTL)
	if err != nil {
		return createErrorResponse(500, "Failed to launch EC2 instance: ", err)
	}

	// Publish provisioning metric after successful launch of EC2 instance
	metrics.PublishProvisioningMetric(ctx)

	// Store the state in DynamoDB
	if err := storeState(ctx, StateEntry{
		ID:          provisionID,
		Environment: req.Environment,
		Region:      req.Region,
		InstanceID:  instanceID,
		Status:      "ACTIVE",
		CreatedAt:   time.Now(),
		ExpiresAt:   time.Now().Add(time.Duration(req.TTL) * time.Hour),
		TTL:         time.Now().Add(time.Duration(req.TTL) * time.Hour).Unix(),
	}, req.Environment, "provision"); err != nil {
		return createErrorResponse(500, "Failed to store state: ", err)
	}

	// TODO: Corellation logs
	logging.LogInfo(fmt.Sprintf(
		"Provision Request: ProvisionID: %s, InstanceID: %s, Environment: %s, Region: %s", provisionID, instanceID, req.Environment, req.Region))

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body: fmt.Sprintf(`{
		"success": true, "provision_id": "%s", "instance_id": "%s"}`, provisionID, instanceID),
	}, nil

}

// lauchEC2Instance launches an EC2 instance using the provided EC2 client,
// configuration, environment, TTL, and custom tags. It returns the instance ID
// of the newly launched instance, or an error if the launch fails.
func lauchEC2Instance(ctx context.Context, client *ec2.Client, config EC2Config, env string, ttl int64) (string, error) {

	provisionID := uuid.New().String()

	// Parse tags
	tags := prepareTags(env, ttl, provisionID, config.Tags)

	// Launch the instance
	launch := &ec2.RunInstancesInput{
		ImageId:      aws.String(config.AMI),
		InstanceType: types.InstanceType(config.InstanceType),
		KeyName:      aws.String(config.KeyName),
		SubnetId:     aws.String(config.SubnetID),
		TagSpecifications: []types.TagSpecification{
			{
				ResourceType: types.ResourceTypeInstance,
				Tags:         tags,
			},
		},
	}

	result, err := client.RunInstances(ctx, launch)
	if err != nil {
		return "", err
	}

	return *result.Instances[0].InstanceId, nil
}

// prepareTags constructs a list of EC2 instance tags based on the provided
// environment, TTL, provision ID, and custom tags. It includes default tags
// such as Environment, ExpiresAt (calculated using the TTL), ProvisionID,
// Service, and Owner. The function then appends any additional custom tags
// provided in the customTags map. Returns a slice of types.Tag to be applied
// to the EC2 instance.
func prepareTags(env string, ttl int64, provisionID string, customTags map[string]string) []types.Tag {

	tags := []types.Tag{
		{
			Key:   aws.String("Environment"),
			Value: aws.String(env),
		},
		{
			Key:   aws.String("ExpiresAt"),
			Value: aws.String(time.Now().Add(time.Duration(ttl) * time.Hour).Format(time.RFC3339)),
		},
		{Key: aws.String("ProvisionID"), Value: aws.String(provisionID)}, // Unique identifier tag
		{Key: aws.String("Service"), Value: aws.String("DynamicProvisioning")},
		{Key: aws.String("Owner"), Value: aws.String("AutomationLambda")},
	}

	// Add custom tags
	for k, v := range customTags {
		tags = append(tags, types.Tag{
			Key:   aws.String(k),
			Value: aws.String(v),
		})
	}

	return tags
}

// createErrorResponse constructs an API Gateway Proxy response with the given
// HTTP status code, error message, and error details. It returns a formatted
// response including a JSON body that indicates the failure, along with the
// original error. The response headers specify JSON content type.
func createErrorResponse(statusCode int, message string, err error) (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode: statusCode,
		Body:       fmt.Sprintf(`{"success": false, "message": "%s", "error": "%v"}`, message, err),
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
	}, fmt.Errorf("%s: %v", message, err)
}

// storeState stores the given StateEntry in DynamoDB. It uses the AWS default
// configuration for the current context. The StateEntry is marshaled to a map
// using the attributevalue package. The item is then put into the DynamoDB table.
func storeState(ctx context.Context, entry StateEntry, environment string, tableType string) error {
	// Create a DynamoDB client
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %s", err)
	}

	tableName, err := ssm.TableName(environment, tableType)
	if err != nil {
		return fmt.Errorf("failed to get table name: %w", err)
	}

	dynamoClient := dynamodb.NewFromConfig(cfg)

	// Marshal the StateEntry struct to a map
	item, err := attributevalue.MarshalMap(entry)
	if err != nil {
		return fmt.Errorf("failed to marshal state entry: %w", err)
	}

	// Put the item into the DynamoDB table
	_, err = dynamoClient.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      item,
	})
	if err != nil {
		return fmt.Errorf("failed to put item in DynamoDB: %w", err)
	}

	return nil
}

// storeStateWithRetries stores the given StateEntry in DynamoDB and retries up to maxEntries times
// if it fails. If all retries fail, it returns an error.
func storeStateWithRetries(ctx context.Context, entry StateEntry, maxEntries int, environment string, tableType string) error {

	for i := 0; i < maxEntries; i++ {
		err := storeState(ctx, entry, environment, tableType)
		if err != nil {
			logging.LogInfo(fmt.Sprintf("Successfully stored state in DynamoDB for InstanceID: %s, provisionID: %s", entry.InstanceID, entry.ID))

			return nil
		}

		logging.LogError(fmt.Sprintf("Failed to store state for ProvisionID: %s (attempt: %d/%d): %v", entry.ID, i+1, maxEntries, err), err)
		time.Sleep(time.Duration(i+1) * time.Second)
	}

	return fmt.Errorf("exceeded maximum retries to store state for provisionID: %s", entry.ID)
}
