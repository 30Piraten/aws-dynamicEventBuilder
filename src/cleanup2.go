// package cleanupenv

// import (
// 	"context"
// 	"encoding/json"
// 	"fmt"
// 	"log"
// 	"os"
// 	"os/exec"
// 	"time"

// 	"github.com/aws/aws-sdk-go-v2/config"
// 	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
// 	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
// 	"github.com/aws/aws-sdk-go/aws"
// )

// // Two important resources for the termination
// // of AWS resources defined / provisioned by
// // Terraform. Resources can be deleted by their
// // Expiry time (TTL -> time to live), and also thier
// // environment.
// type Resource struct {
// 	// Environment (e.g., dev, staging, prod)
// 	Environment string `json:"environment"`
// 	// Expiry timestamp
// 	TTL int64 `json:"ttl"`
// }

// // initHandler is the entry point for the cleanup Lambda
// func InitHandler(ctx context.Context) (string, error) {
// 	// Load AWS configuration
// 	config, err := config.LoadDefaultConfig(ctx)
// 	if err != nil {
// 		log.Fatalf("Unable to load AWS configuration, %v", err)
// 	}

// 	// Create DynamoDB client
// 	dynamoClient := dynamodb.NewFromConfig(config)

// 	// Query DynamoDB resources
// 	expiredResources, err := queryExpiredResources(ctx, dynamoClient)
// 	if err != nil {
// 		log.Fatalf("Error querying expired resources: %v", err)
// 	}

// 	// Destroy expired resources
// 	for _, resource := range expiredResources {
// 		err := destroyResources(resource.Environment)
// 		if err != nil {
// 			log.Printf("Error destroying resources for %s: %v", resource.Environment, err)
// 		} else {
// 			// TODO: invalid type!
// 			log.Printf("Successfully destroyed resources for %s", resource.Environment)
// 		}
// 	}

// 	return "Environment cleanup completed", nil
// }

// // queryExpiredResources fetches expired resources from DynamoDB
// func queryExpiredResources(ctx context.Context, dbClient *dynamodb.Client) ([]Resource, error) {
// 	tableName := os.Getenv("DYNAMODB_TABLE")
// 	if tableName == "" {
// 		tableName = "<your table name>"
// 	}

// 	// Query items where TTL has expired
// 	input := &dynamodb.ScanInput{
// 		TableName:        &tableName,
// 		FilterExpression: aws.String("ttl < :current_time"),
// 		ExpressionAttributeValues: map[string]types.AttributeValue{
// 			":current_time": &types.AttributeValueMemberN{
// 				Value: fmt.Sprintf("%d", getCurrentTime())},
// 		},
// 	}

// 	response, err := dbClient.Scan(ctx, input)
// 	if err != nil {
// 		return nil, fmt.Errorf("Error querying DynamoDB: %v", err)
// 	}

// 	var resources []Resource
// 	for _, item := range response.Items {
// 		resource := Resource{}
// 		err := attributeValueToStruct(item, &resource)
// 		if err != nil {
// 			log.Printf("Error converting attribute value to struct: %v", err)
// 			continue
// 		}
// 		resources = append(resources, resource)
// 	}
// 	return resources, nil
// }

// // destroyResources triggers Terraform commands to destroy resources for a given environment
// func destroyResources(environment string) error {
// 	log.Printf("Destroying resources for environment: %s", environment)

// 	cmd := exec.Command("terraform", "destroy", "-var", fmt.Sprintf("environment=%s", environment), "-auto-approve")
// 	cmd.Dir = os.Getenv("TERRAFORM_DIR")

// 	output, err := cmd.CombinedOutput()
// 	if err != nil {
// 		return fmt.Errorf("terraform destroy failed: %v\nOutput: %s", err, string(output))
// 	}
// 	log.Printf("Terraform output: %s", string(output))

// 	return nil
// }

// // getCurrentTime returns the current Unix timestamp in seconds
// func getCurrentTime() int64 {
// 	return time.Now().Unix()
// }

// // attributeValueToStruct converts a map of attribute values to a Go struct
// func attributeValueToStruct(attributes map[string]types.AttributeValue, output interface{}) error {
// 	data, err := json.Marshal(attributes)
// 	if err != nil {
// 		return fmt.Errorf("Error marshalling attribute values: %v", err)
// 	}
// 	return json.Unmarshal(data, output)
// }
