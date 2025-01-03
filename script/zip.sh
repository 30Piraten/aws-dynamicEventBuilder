#!/bin/bash

# CleanupEnv Function
cd lambda-functions/cleanupenv
GOOS=linux GOARCH=amd64 go build -o main cleanup.go
zip cleanupenv_payload.zip cleanup.go
cd -

# ProvisionEnv Function
cd lambda-functions/provisionenv
GOOS=linux GOARCH=amd64 go build -o main proenv.go
zip proenv_payload.zip proenv.go
cd -