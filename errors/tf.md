# Error occured after running: terraform init
- cause: backend.tf

Error: Failed to get existing workspaces: S3 bucket "dynamiceventbuilder-bucket-v01" does not exist.
│ 
│ The referenced S3 bucket must have been previously created. If the S3 bucket
│ was created within the last minute, please wait for a minute or two and try
│ again.
│ 
│ Error: operation error S3: ListObjectsV2, https response error StatusCode: 404, RequestID: QCSRV1344HQT21MA, HostID: fSgHZbTShRirMuX0kZnAEQRHkciFBON1dVKNOsF3Hwv27FmiDvdjH3rWVFtkcFxFtMAGCuVnqko=, NoSuchBucket: 
│ 


# Error occured after running: terraform init
Error: Error acquiring the state lock
│ 
│ Error message: operation error DynamoDB: PutItem, https response error StatusCode: 400, RequestID: 2D7TG7G5737ASU2SBI1RC8FI3JVV4KQNSO5AEMVJF66Q9ASUAAJG, api error ValidationException: One or
│ more parameter values were invalid: Missing the key EnvironmentName in the item
│ Unable to retrieve item from DynamoDB table "dev-dynamodb-table": operation error DynamoDB: GetItem, https response error StatusCode: 400, RequestID:
│ O5ADBJU1GUSDC9HEBBG7399MRJVV4KQNSO5AEMVJF66Q9ASUAAJG, api error ValidationException: The provided key element does not match the schema
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try