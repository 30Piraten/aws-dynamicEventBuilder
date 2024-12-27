package main

import (
	cleanup "github.com/30Piraten/aws_dynamicEventBuilder/lambda-functions/cleanupenv"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(cleanup.HandleCleanUpRequest)
}
