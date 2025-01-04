package main

import (
	// cleanup "github.com/30Piraten/aws-dynamicEventBuilder/lambda-functions/cleanupenv"
	proenv "github.com/30Piraten/aws-dynamicEventBuilder/lambda-functions/provisionenv"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	// lambda.Start(cleanup.HandleCleanupRequest)
	lambda.Start(proenv.HandleProvisionRequest)
}
