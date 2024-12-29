package main

import (
	"context"
	"encoding/json"
	"errors"
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
	"github.com/aws/aws-sdk-go/service/ec2"
)

type StateEntry struct {
	ID            string    `json:"id"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
	ResourceState string    `json:"resource_state"`
}

type EC2Config struct {
	InstanceType string `json:"instance_type"`
	Region       string `json:"region"`
	OS           string `json:"os"`
}

var (
	dynamoClient = dynamodb.New(session.Must(session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("AWS_REGION")),
	})))
)

func createErrorResponse(status int, message string, err error) (events.APIGatewayProxyResponse, error) {
	log.Printf("Error: %s, Details: %v", message, err)
	response := map[string]interface{}{
		"success": false,
		"message": message,
	}
	if err != nil {
		response["error"] = err.Error()
	}
	responseBody, _ := json.Marshal(response)
	return events.APIGatewayProxyResponse{
		StatusCode: status,
		Body:       string(responseBody),
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

func updateStateStatus(provisionID, status, resourceState string) error {
	updateInput := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key: map[string]*dynamodb.AttributeValue{
			"ID": {S: aws.String(provisionID)},
		},
		UpdateExpression: aws.String("SET #st = :status, #rs = :resourceState, #ua = :updatedAt"),
		ExpressionAttributeNames: map[string]*string{
			"#st": aws.String("Status"),
			"#rs": aws.String("ResourceState"),
			"#ua": aws.String("UpdatedAt"),
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":status":        {S: aws.String(status)},
			":resourceState": {S: aws.String(resourceState)},
			":updatedAt":     {S: aws.String(time.Now().UTC().Format(time.RFC3339))},
		},
	}

	_, err := dynamoClient.UpdateItem(updateInput)
	if err != nil {
		log.Printf("Failed to update state: %v", err)
		return err
	}
	return nil
}

func getLatestAMI(region, osType string) (string, error) {
	svc := ec2.New(session.Must(session.NewSession(&aws.Config{Region: aws.String(region)})))
	filters := []*ec2.Filter{
		{
			Name:   aws.String("name"),
			Values: []*string{aws.String(fmt.Sprintf("%s-*", osType))},
		},
		{
			Name:   aws.String("state"),
			Values: []*string{aws.String("available")},
		},
	}

	describeImagesInput := &ec2.DescribeImagesInput{
		Filters: filters,
	}

	result, err := svc.DescribeImages(describeImagesInput)
	if err != nil {
		return "", fmt.Errorf("failed to fetch latest AMI: %w", err)
	}

	if len(result.Images) == 0 {
		return "", errors.New("no available AMI found")
	}

	latestImage := result.Images[0] // Select the first available image
	return aws.StringValue(latestImage.ImageId), nil
}

func HandleProvisionRequest(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Processing provision request: %s", req.Body)

	var config EC2Config
	if err := json.Unmarshal([]byte(req.Body), &config); err != nil {
		return createErrorResponse(400, "Invalid request payload", err)
	}

	amiID, err := getLatestAMI(config.Region, config.OS)
	if err != nil {
		return createErrorResponse(500, "Failed to fetch latest AMI", err)
	}

	workingDir := filepath.Join(os.Getenv("TERRAFORM_WORKING_DIR"), config.InstanceType)
	if err := os.MkdirAll(workingDir, 0755); err != nil {
		return createErrorResponse(500, "Failed to create Terraform working directory", err)
	}

	createCmd := exec.Command("terraform", "apply", "-auto-approve", "-no-color")
	createCmd.Dir = workingDir
	createCmd.Env = append(os.Environ(), "TF_IN_AUTOMATION=true")

	if output, err := createCmd.CombinedOutput(); err != nil {
		return createErrorResponse(500, "Failed to provision resources", fmt.Errorf("output: %s, error: %v", output, err))
	}

	if err := updateStateStatus(config.InstanceType, "PROVISIONED", ""); err != nil {
		return createErrorResponse(500, "Failed to update state", err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       `{"success": true, "message": "Resources provisioned successfully"}`,
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

func HandleCleanupRequest(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Processing cleanup request: %s", req.Body)

	var input struct {
		ProvisionID string `json:"provision_id"`
	}
	if err := json.Unmarshal([]byte(req.Body), &input); err != nil {
		return createErrorResponse(400, "Invalid request format", err)
	}

	result, err := dynamoClient.GetItem(&dynamodb.GetItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key: map[string]*dynamodb.AttributeValue{
			"ID": {S: aws.String(input.ProvisionID)},
		},
	})
	if err != nil || result.Item == nil {
		return createErrorResponse(404, "Provision ID not found", err)
	}

	var state StateEntry
	if err := dynamodbattribute.UnmarshalMap(result.Item, &state); err != nil {
		return createErrorResponse(500, "Failed to parse state entry", err)
	}

	workingDir := filepath.Join(os.Getenv("TERRAFORM_WORKING_DIR"), input.ProvisionID)
	destroyCmd := exec.Command("terraform", "destroy", "-auto-approve", "-no-color")
	destroyCmd.Dir = workingDir
	destroyCmd.Env = append(os.Environ(), "TF_IN_AUTOMATION=true")

	if output, err := destroyCmd.CombinedOutput(); err != nil {
		return createErrorResponse(500, "Failed to destroy resources", fmt.Errorf("output: %s, error: %v", output, err))
	}

	if err := updateStateStatus(input.ProvisionID, "DELETED", ""); err != nil {
		return createErrorResponse(500, "Failed to update state", err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       `{"success": true, "message": "Resources cleaned up successfully"}`,
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}
