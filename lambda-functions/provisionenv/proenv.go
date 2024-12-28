// Package provisionenv provides AWS resource provisioning and cleanup functionality
package provisionenv

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
	"github.com/google/uuid"
)

// ResourceConfig defines the structure for various AWS resource configurations
type ResourceConfig struct {
	EC2         *EC2Config         `json:"ec2,omitempty"`
	RDS         *RDSConfig         `json:"rds,omitempty"`
	S3          *S3Config          `json:"s3,omitempty"`
	VPC         *VPCConfig         `json:"vpc,omitempty"`
	ECS         *ECSConfig         `json:"ecs,omitempty"`
	ElastiCache *ElastiCacheConfig `json:"elasticache,omitempty"`
	Monitoring  *MonitoringConfig  `json:"monitoring,omitempty"`
}

// MonitoringConfig defines the structure for monitoring configurations
type MonitoringConfig struct {
	Enabled         bool   `json:"enabled"`
	MonitoringType  string `json:"monitoring_type"`
	NotificationARN string `json:"notification_arn"`
}

// ECSConfig defines the structure for ECS configurations
type ECSConfig struct {
	ClusterName    string `json:"cluster_name"`
	TaskDefinition string `json:"task_definition"`
	DesiredCount   int    `json:"desired_count"`
	LaunchType     string `json:"launch_type"`
}

// EC2Config defines the structure for EC2 configurations
type EC2Config struct {
	InstanceType   string   `json:"instance_type"`
	KeyName        string   `json:"key_name"`
	SecurityGroups []string `json:"security_groups"`
}

// RDSConfig defines the structure for RDS configurations
type RDSConfig struct {
	DBInstanceIdentifier string `json:"db_instance_identifier"`
	DBInstanceClass      string `json:"db_instance_class"`
	Engine               string `json:"engine"`
	AllocatedStorage     int    `json:"allocated_storage"`
}

// S3Config defines the structure for S3 configurations
type S3Config struct {
	BucketName string `json:"bucket_name"`
	Region     string `json:"region"`
}

// ElastiCacheConfig defines the structure for ElastiCache configurations
type ElastiCacheConfig struct {
	ClusterName string `json:"cluster_name"`
	NodeType    string `json:"node_type"`
	NumNodes    int    `json:"num_nodes"`
}

// VPCConfig defines the structure for VPC configurations
type VPCConfig struct {
	CidrBlock          string   `json:"cidr_block"`
	EnableDnsSupport   bool     `json:"enable_dns_support"`
	EnableDnsHostnames bool     `json:"enable_dns_hostnames"`
	Subnets            []string `json:"subnets"`
}

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

// Define input type
type ProvisionInput struct {
	Environment string            `json:"environment"`
	Region      string            `json:"region"`
	Resources   ResourceConfig    `json:"resources"`
	TTL         int64             `json:"ttl"` // TTL in hours
	Tags        map[string]string `json:"tags"`
}

// HandleProvisionRequest handles incoming API Gateway requests for resource provisioning
func HandleProvisionRequest(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Processing provision request: %s", req.Body)

	// Parse and validate request
	var input ProvisionInput

	if err := json.Unmarshal([]byte(req.Body), &input); err != nil {
		return createErrorResponse(400, "Invalid request format", err)
	}

	// Generate unique ID and create state entry
	provisionID := uuid.New().String()
	expirationTime := time.Now().Add(time.Duration(input.TTL) * time.Hour)

	entry := StateEntry{
		ID:          provisionID,
		Environment: input.Environment,
		Region:      input.Region,
		Status:      "INITIALIZING",
		CreatedAt:   time.Now(),
		ExpiresAt:   expirationTime,
		TTL:         expirationTime.Unix(),
		Tags:        input.Tags,
	}

	// Store initial state
	if err := storeState(entry); err != nil {
		return createErrorResponse(500, "Failed to store state", err)
	}

	// Create and apply Terraform configuration
	if err := provisionResources(input, provisionID); err != nil {
		updateStateStatus(provisionID, "FAILED", err.Error())
		return createErrorResponse(500, "Resource provisioning failed", err)
	}

	// Update state to success
	updateStateStatus(provisionID, "ACTIVE", "")

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       fmt.Sprintf(`{"success": true, "provision_id": "%s"}`, provisionID),
		Headers:    map[string]string{"Content-Type": "application/json"},
	}, nil
}

// cleanup

func provisionResources(input ProvisionInput, provisionID string) error {
	workingDir := filepath.Join(os.Getenv("TERRAFORM_WORKING_DIR"), provisionID)

	// Create Terraform working directory
	if err := os.MkdirAll(workingDir, 0755); err != nil {
		return fmt.Errorf("failed to create working directory: %v", err)
	}

	// Generate Terraform configuration files
	if err := generateTerraformConfig(workingDir, struct {
		Environment string
		Region      string
		Resources   ResourceConfig
		TTL         int64
		Tags        map[string]string
	}{
		Environment: input.Environment,
		Region:      input.Region,
		Resources:   input.Resources,
		TTL:         input.TTL,
		Tags:        input.Tags,
	}); err != nil {
		return fmt.Errorf("failed to generate terraform config: %v", err)
	}

	// Initialize and apply Terraform
	if err := applyTerraformConfig(workingDir); err != nil {
		return fmt.Errorf("failed to apply terraform config: %v", err)
	}

	return nil
}

// Additional helper functions...

func storeState(entry StateEntry) error {
	av, err := dynamodbattribute.MarshalMap(entry)
	if err != nil {
		return err
	}

	_, err = dynamoClient.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Item:      av,
	})
	return err
}

func updateStateStatus(id, status, errorMsg string) error {
	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key: map[string]*dynamodb.AttributeValue{
			"ID": {S: aws.String(id)},
		},
		UpdateExpression: aws.String("SET #status = :status, errorMessage = :error"),
		ExpressionAttributeNames: map[string]*string{
			"#status": aws.String("status"),
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":status": {S: aws.String(status)},
			":error":  {S: aws.String(errorMsg)},
		},
	}

	_, err := dynamoClient.UpdateItem(input)
	return err
}

// Previous code remains the same...

// generateTerraformConfig creates the necessary Terraform configuration files
func generateTerraformConfig(workingDir string, input struct {
	Environment string
	Region      string
	Resources   ResourceConfig
	TTL         int64
	Tags        map[string]string
}) error {
	// Create main.tf with provider and backend configuration
	mainConfig := fmt.Sprintf(`
terraform {
    required_version = ">= 1.0.0"
    
    backend "s3" {
        bucket         = "%s"
        key            = "states/%s.tfstate"
        region         = "%s"
        dynamodb_table = "%s"
        encrypt        = true
    }
}

provider "aws" {
    region = "%s"
    
    default_tags {
        tags = {
            Environment = "%s"
            ManagedBy   = "terraform"
            ExpiresAt   = "%s"
        }
    }
}

# Common Variables
variable "environment" {
    type    = string
    default = "%s"
}

variable "region" {
    type    = string
    default = "%s"
}
`,
		os.Getenv("STATE_BUCKET"),
		input.Environment,
		input.Region,
		os.Getenv("TERRAFORM_LOCK_TABLE"),
		input.Region,
		input.Environment,
		time.Now().Add(time.Duration(input.TTL)*time.Hour).Format(time.RFC3339),
		input.Environment,
		input.Region,
	)

	if err := os.WriteFile(filepath.Join(workingDir, "main.tf"), []byte(mainConfig), 0644); err != nil {
		return fmt.Errorf("failed to write main.tf: %v", err)
	}

	// Generate module configurations for each resource type
	if input.Resources.VPC != nil {
		if err := generateVPCModule(workingDir, input.Resources.VPC); err != nil {
			return fmt.Errorf("failed to generate VPC module: %v", err)
		}
	}

	if input.Resources.EC2 != nil {
		if err := generateEC2Module(workingDir, input.Resources.EC2); err != nil {
			return fmt.Errorf("failed to generate EC2 module: %v", err)
		}
	}

	// Add other resource module generations as needed...

	return nil
}

// generateEC2Module creates the Terraform configuration for EC2 resources
func generateEC2Module(workingDir string, config *EC2Config) error {
	ec2Config := fmt.Sprintf(`
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "%s"
  key_name      = "%s"

  vpc_security_group_ids = %v

  tags = {
	Name = "ExampleInstance"
  }
}
`, config.InstanceType, config.KeyName, config.SecurityGroups)

	if err := os.WriteFile(filepath.Join(workingDir, "ec2.tf"), []byte(ec2Config), 0644); err != nil {
		return fmt.Errorf("failed to write ec2.tf: %v", err)
	}

	return nil
}

// generateVPCModule creates the Terraform configuration for VPC resources
func generateVPCModule(workingDir string, config *VPCConfig) error {
	vpcConfig := fmt.Sprintf(`
	module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "%s"
  cidr = "%s"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = %v
  public_subnets  = %v

  enable_dns_support   = %t
  enable_dns_hostnames = %t

  tags = {
	Terraform   = "true"
	Environment = "%s"
  }
}
`, config.CidrBlock, config.CidrBlock, config.Subnets, config.Subnets, config.EnableDnsSupport, config.EnableDnsHostnames, os.Getenv("ENVIRONMENT"))

	if err := os.WriteFile(filepath.Join(workingDir, "vpc.tf"), []byte(vpcConfig), 0644); err != nil {
		return fmt.Errorf("failed to write vpc.tf: %v", err)
	}

	return nil
}

// createErrorResponse generates a standardized error response for API Gateway
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

// applyTerraformConfig initializes and applies the Terraform configuration
func applyTerraformConfig(workingDir string) error {
	// Set up environment variables for Terraform
	env := append(os.Environ(),
		"TF_IN_AUTOMATION=true",
		"TF_LOG=INFO",
		fmt.Sprintf("TF_LOG_PATH=%s/terraform.log", workingDir),
	)

	// Initialize Terraform
	initCmd := exec.Command("terraform", "init",
		"-input=false",
		"-no-color",
	)
	initCmd.Dir = workingDir
	initCmd.Env = env

	if output, err := initCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("terraform init failed: %v, output: %s", err, output)
	}

	// Run Terraform plan
	planCmd := exec.Command("terraform", "plan",
		"-input=false",
		"-no-color",
		"-out=tfplan",
	)
	planCmd.Dir = workingDir
	planCmd.Env = env

	if output, err := planCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("terraform plan failed: %v, output: %s", err, output)
	}

	// Apply Terraform configuration
	applyCmd := exec.Command("terraform", "apply",
		"-input=false",
		"-no-color",
		"-auto-approve",
		"tfplan",
	)
	applyCmd.Dir = workingDir
	applyCmd.Env = env

	if output, err := applyCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("terraform apply failed: %v, output: %s", err, output)
	}

	// Capture and store Terraform state
	showCmd := exec.Command("terraform", "show", "-json")
	showCmd.Dir = workingDir
	showOutput, err := showCmd.Output()
	if err != nil {
		return fmt.Errorf("failed to capture terraform state: %v", err)
	}

	// Store the Terraform state in DynamoDB
	if err := updateTerraformState(workingDir, string(showOutput)); err != nil {
		return fmt.Errorf("failed to store terraform state: %v", err)
	}

	return nil
}

func updateTerraformState(workingDir, state string) error {
	// Extract provision ID from working directory
	provisionID := filepath.Base(workingDir)

	input := &dynamodb.UpdateItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key: map[string]*dynamodb.AttributeValue{
			"ID": {S: aws.String(provisionID)},
		},
		UpdateExpression: aws.String("SET terraform_state = :state"),
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":state": {S: aws.String(state)},
		},
	}

	_, err := dynamoClient.UpdateItem(input)
	return err
}
