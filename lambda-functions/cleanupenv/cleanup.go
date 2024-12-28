package cleanupenv

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

// StateEntry represents the DynamoDB record for tracking provisioned environments
type StateEntry struct {
	ID             string            `json:"id"`              // Unique identifier for the provision request
	Environment    string            `json:"environment"`     // Environment name (dev/staging/prod)
	Region         string            `json:"region"`          // AWS region
	Resources      string            `json:"resources"`       // JSON string of provisioned resources
	Status         string            `json:"status"`          // Current status of provisioning
	CreatedAt      time.Time         `json:"created_at"`      // Creation timestamp
	ExpiresAt      time.Time         `json:"expires_at"`      // Expiration timestamp
	TTL            int64             `json:"ttl"`             // Time-to-live in Unix timestamp
	Tags           map[string]string `json:"tags,omitempty"`  // Resource tags
	TerraformState string            `json:"terraform_state"` // Terraform state file content
}

// DynamoDB client initialization
var dynamoClient *dynamodb.DynamoDB

func init() {
	sess := session.Must(session.NewSession())
	dynamoClient = dynamodb.New(sess)
}

// HandleCleanupRequest handles cleanup of expired resources
func HandleCleanupRequest(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Println("Starting cleanup of expired resources")

	// Query DynamoDB for expired entries
	expiredEntries, err := queryExpiredEntries()
	if err != nil {
		return createErrorResponse(500, "Failed to query expired entries", err)
	}

	// Process each expired entry
	for _, entry := range expiredEntries {
		if err := cleanupResources(entry.ID); err != nil {
			log.Printf("Failed to cleanup resources for ID %s: %v", entry.ID, err)
			continue
		}
		log.Printf("Successfully cleaned up resources for ID %s", entry.ID)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       fmt.Sprintf(`{"success": true, "cleaned_up": %d}`, len(expiredEntries)),
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

// cleanupResources handles the destruction of provisioned resources
func cleanupResources(provisionID string) error {
	workingDir := filepath.Join(os.Getenv("TERRAFORM_WORKING_DIR"), provisionID)

	// Run terraform destroy
	cmd := exec.Command("terraform", "destroy", "-auto-approve")
	cmd.Dir = workingDir

	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("terraform destroy failed: %v, output: %s", err, output)
	}

	// Clean up DynamoDB entry and working directory
	if err := deleteStateEntry(provisionID); err != nil {
		return fmt.Errorf("failed to delete state entry: %v", err)
	}

	return os.RemoveAll(workingDir)
}

func queryExpiredEntries() ([]StateEntry, error) {
	currentTime := time.Now().Unix()

	input := &dynamodb.QueryInput{
		TableName:              aws.String(os.Getenv("DYNAMODB_TABLE")),
		IndexName:              aws.String("TTLIndex"),
		KeyConditionExpression: aws.String("TTL <= :now"),
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":now": {N: aws.String(fmt.Sprintf("%d", currentTime))},
		},
	}

	var entries []StateEntry
	result, err := dynamoClient.Query(input)
	if err != nil {
		return nil, err
	}

	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &entries)
	return entries, err
}

// deleteStateEntry removes the provisioning state entry from DynamoDB
func deleteStateEntry(id string) error {
	tableName := os.Getenv("DYNAMODB_TABLE")
	if tableName == "" {
		return fmt.Errorf("DYNAMODB_TABLE environment variable not set")
	}

	input := &dynamodb.DeleteItemInput{
		TableName: aws.String(tableName),
		Key: map[string]*dynamodb.AttributeValue{
			"ID": {
				S: aws.String(id),
			},
		},
	}

	_, err := dynamoClient.DeleteItem(input)
	return err
}

func createErrorResponse(statusCode int, message string, err error) (events.APIGatewayProxyResponse, error) {
	errResponse := struct {
		Success bool   `json:"success"`
		Message string `json:"message"`
		Error   string `json:"error,omitempty"`
	}{
		Success: false,
		Message: message,
	}

	if err != nil {
		errResponse.Error = err.Error()
	}

	body, err := json.Marshal(errResponse)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to marshal error response: %v", err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: statusCode,
		Body:       string(body),
		Headers: map[string]string{
			"Content-Type": "application/json",
			"X-Error-Type": message,
		},
	}, nil
}
