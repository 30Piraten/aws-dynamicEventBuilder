.PHONY: build build-ProvisionEnvFunction

BINARY_NAME=bootstrap
OUTPUT_BINARY=bootstrap

build:
	@echo "Building the binary..."
	GOOS=linux GOARCH=amd64 go build -o $(OUTPUT_BINARY) proenv.go
	@echo "Setting executable permissions..."
	chmod +x $(OUTPUT_BINARY)
	chmod +x $(BINARY_NAME)

build-ProvisionEnvFunction: build
	@echo "ProvisionEnvFunction built successfully."
