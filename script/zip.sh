#!/bin/bash

# CleanupEnv Function
cd lambda-functions/cleanupenv
GOOS=linux GOARCH=amd64 go build -o main cleanup.go
zip lambda_function_payload.zip main
cd -

# ProvisionEnv Function
cd lambda-functions/provisionenv
GOOS=linux GOARCH=amd64 go build -o main proenv.go
zip lambda_function_payload.zip main
cd -