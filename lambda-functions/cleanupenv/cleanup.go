package cleanupenv

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/30Piraten/aws-dynamicEventBuilder/lambda-functions/provisionenv"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go/aws"
)

var StateEntry provisionenv.StateEntry

// HandleCleanupRequest is the handler for the cleanup
// of expired EC2 instances
func HandleCleanupRequest(ctx context.Context, event events.CloudWatchEvent) error {

	// Initialise the AWS config
	config, err := config.LoadDefaultConfig(ctx)

	if err != nil {
		return fmt.Errorf("failed to load SDK configuration, %v", err)
	}

	// Create clients
	ec2Client := ec2.NewFromConfig(config)
	dynamodbClient := dynamodb.NewFromConfig(config)

	// Get the expired instances
	expiredInstances, err := getExpiredInstances(ctx, dynamodbClient)
	if err != nil {
		return fmt.Errorf("failed to get expired instances, %v", err)
	}

	// Terminate expired instances
	for _, instance := range expiredInstances {
		if err := terminateInstance(ctx, ec2Client, instance); err != nil {
			log.Printf("Failed to terminate instance %s: %v", instance.InstanceID, err)
			continue
		}

		if err := markInstanceAsTerminated(ctx, dynamodbClient, instance.ID); err != nil {
			log.Printf("Failed to update instance status %s: %v", instance.ID, err)
		}
	}
	return nil
}

func getExpiredInstances(ctx context.Context, client *dynamodb.Client) ([]provisionenv.StateEntry, error) {

	currentTime := time.Now().Unix()

	input := &dynamodb.QueryInput{
		TableName:              aws.String(os.Getenv("DYNAMODB_TABLE_NAME")),
		IndexName:              aws.String("TTLIndex"),
		KeyConditionExpression: aws.String("TTL <= :now AND #status = :status"),
		ExpressionAttributeNames: map[string]string{
			"#status": "status",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":now": &types.AttributeValueMemberN{
				Value: fmt.Sprintf("%d", currentTime),
			},
			":status": &types.AttributeValueMemberS{Value: "ACTIVE"},
		},
	}

	result, err := client.Query(ctx, input)
	if err != nil {
		return nil, err
	}

	var instances []provisionenv.StateEntry
	err = attributevalue.UnmarshalListOfMaps(result.Items, &instances)
	return instances, err
}

func terminateInstance(ctx context.Context, client *ec2.Client, instance provisionenv.StateEntry) error {
	input := &ec2.TerminateInstancesInput{
		InstanceIds: []string{instance.InstanceID},
	}

	_, err := client.TerminateInstances(ctx, input)

	return err
}

func markInstanceAsTerminated(ctx context.Context, client *dynamodb.Client, instanceID string) error {

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE_NAME")),
		Key: map[string]types.AttributeValue{
			"ID": &types.AttributeValueMemberS{
				Value: instanceID,
			},
		},
		UpdateExpression: aws.String("SET #status = :status"),
		ExpressionAttributeNames: map[string]string{
			"#status": "status",
		},
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":status": &types.AttributeValueMemberS{
				Value: "TERMINATED",
			},
		},
	}

	_, err := client.UpdateItem(ctx, input)

	return err
}
