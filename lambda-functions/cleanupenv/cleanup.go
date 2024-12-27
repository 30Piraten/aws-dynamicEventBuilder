package cleanupenv

import (
	"context"
	"log"
	"os"
	"os/exec"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// Explanation: This Lambda function scans the DynamoDB table for expired resources and destroys them using Terraform.
func HandleCleanUpRequest(ctx context.Context) (string, error) {
	// Logic to clean up environments, e.g., terminate AWS resources (EC2, VPC, S3, RDS, etc) instances based on TTL
	config, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	dynamoClient := dynamodb.NewFromConfig(config)

	// Get the table name from the environment variable
	tableName := os.Getenv("TABLE_NAME")

	scanInput := &dynamodb.ScanInput{
		TableName: aws.String(tableName),
	}

	result, err := dynamoClient.Scan(ctx, scanInput)
	if err != nil {
		log.Fatalf("failed to scan table, %v", err)
	}

	for _, item := range result.Items {
		env := item["EnvironmentName"].S
		ttl, err := strconv.ParseInt(*item["TTL"].N, 10, 64)
		if err != nil || time.Now().Unix() > ttl {
			log.Printf("Cleaning up expired environment: %s", env)
			cleanupEnvironment(*environment)
		}
	}

	return "Environment cleanup completed", nil
}

func cleanupEnvironment(environment string) {
	// Logic to destroy the environment using Terraform
	cmd := exec.Command("terraform", "destroy", "-var", "environment="+env, "-auto-approve")

	// Directory with Terraform configuration files
	cmd.Dir = os.Getenv("TERRAFORM_DIR")

	if err := cmd.Run(); err != nil {
		log.Fatalf("failed to destroy environment %s: %v", environment, err)
	}
}
