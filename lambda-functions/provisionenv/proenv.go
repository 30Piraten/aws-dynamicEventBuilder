package provisionenv

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
)

// Request defines the input payload structure received from API Gateway
type Request struct {
	Environment   string `json:"environment"`
	ResourceSizes string `json:"resource_sizes"`
}

// Response defines the structure of the output payload sent back to API Gateway
type Response struct {
	Message string `json:"message"`
	Status  string `json:"status"`
}

// HandleProvisionRequest is the entry point for the Lambda function
func HandleProvisionRequest(ctx context.Context, event Request) (Response, error) {
	log.Printf("Provisioning environment: %s", event.Environment)

	// Validate input
	if event.Environment == "" || event.ResourceSizes == "" {
		return Response{Message: "Environment and resource sizes are required", Status: "Failed"}, nil
	}

	// Trigger provisioning of resources
	err := provisionResources(event.Environment, event.ResourceSizes)
	if err != nil {
		log.Printf("Failed to provision resources: %v", err)
		return Response{Message: "Provisioning failed", Status: "Failed"}, nil
	}

	return Response{Message: "Resources provisioned successfully", Status: "Success"}, nil
}

// provisionResources truggers Terraform commands to provision resources
func provisionResources(environment, resourceSizes string) error {
	log.Printf("Provisioning resources for environment: %s with size:  %s", environment, resourceSizes)

	// Construct the Terraform command
	cmd := exec.Command("terraform", "apply", "-var", fmt.Sprintf("enviromnent=%s", environment), "-var", fmt.Sprintf("resourceSizes=%s", resourceSizes), "-auto-approve")
	// Terraform configuration directory
	cmd.Dir = os.Getenv("TERRAFORM_DIR")

	// Run the command and capture the output
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("terraform apply failed: %v\nOutput: %s", err, string(output))
	}

	log.Printf("Terraform output: %s", string(output))

	return nil
}
