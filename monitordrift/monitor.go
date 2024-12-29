package monitordrift

import (
	"context"
	"fmt"

	"github.com/30Piraten/aws-dynamicEventBuilder/lambda-functions/cleanupenv"
	"github.com/30Piraten/aws-dynamicEventBuilder/logging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	ec2Types "github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/aws/aws-sdk-go/aws"
)

// ActiveInstance represents the structure of an instance record in DynamoDB
type ActiveInstance struct {
	ID         string `dynamodbv:"ID"`
	InstanceID string `dynamodbv:"instance_id"`
	Status     string `dynamodbv:"status"`
}

func monitorDrift(ctx context.Context) error {
	config, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %v", err)
	}

	ec2Client := ec2.NewFromConfig(config)
	dynamodbClient := dynamodb.NewFromConfig(config)

	// Fetch all active instances from DynamoDB
	activeInstances, err := getActiveInstances(ctx, dynamodbClient)
	if err != nil {
		return fmt.Errorf("failed to fetch active instances: %v", err)
	}

	// Fetch all running instances from EC2
	runningInstances, err := listRunningInstances(ctx, ec2Client)
	if err != nil {
		return fmt.Errorf("failed to fetch running instances: %v", err)
	}

	// Compare active instances in DynamoDB against running EC2 instances
	for _, activeInstance := range activeInstances {
		if !instanceExistsInEC2(runningInstances, activeInstance.InstanceID) {
			logging.LogInfo(fmt.Sprintf("Instance %s (ProvisionID: %s) not found in EC2, marking as TERMINATED", activeInstance.InstanceID, activeInstance.ID))

			if err := cleanupenv.MarkInstanceAsTerminated(ctx, dynamodbClient, activeInstance.ID); err != nil {
				logging.LogError(fmt.Sprintf("Failed to update DynamoDB status for InstanceID: %s: %v", activeInstance.InstanceID, err), err)
			}
		}
	}
	return nil
}

func getActiveInstances(ctx context.Context, client *dynamodb.Client) ([]ActiveInstance, error) {

	// Query DyanmoDB for active instances
	input := &dynamodb.ScanInput{
		TableName:        aws.String("dev-dynamodb-table"),
		FilterExpression: aws.String("Sattus = :status"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":status": &types.AttributeValueMemberS{
				Value: "ACTIVE",
			},
		},
	}

	result, err := client.Scan(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("error querying DynamoDb: %v", err)
	}

	var activeInstances []ActiveInstance
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &activeInstances); err != nil {

		return nil, fmt.Errorf("error unmarshalling DynamoDB results: %v", err)
	}

	return activeInstances, nil
}

func listRunningInstances(ctx context.Context, client *ec2.Client) ([]string, error) {
	input := &ec2.DescribeInstancesInput{}
	result, err := client.DescribeInstances(ctx, input)
	if err != nil {
		return nil, err
	}

	var instanceIDs []string
	for _, response := range result.Reservations {
		for _, inst := range response.Instances {
			if inst.State.Name == ec2Types.InstanceStateNameRunning {
				instanceIDs = append(instanceIDs, *inst.InstanceId)
			}
		}
	}

	return instanceIDs, nil
}

func instanceExistsInEC2(runningInstances []string, instanceID string) bool {
	for _, id := range runningInstances {
		if id == instanceID {
			return true
		}
	}

	return false
}
