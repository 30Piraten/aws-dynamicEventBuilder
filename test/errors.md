 Uploading to proenv-app/4e747c04f8d565483c7b513d2c9a3f21.template  355 / 355  (100.00%)
Error: Failed to create changeset for the stack: proenv-app, An error occurred (ValidationError) when calling the CreateChangeSet operation: Template format error: Unrecognized resource types: [AWS::Serverless::Function]

    - The error indicates that the `AWS::Serverless::Function` resource type is not recognized. This typically happens when the AWS Serverless Application Model (SAM) transform is not specified in the template.

To resolve this, ensure that your `template.yaml` file includes the `Transform` section at the top. Update your `template.yaml` file as follows:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Resources:
  ProvisionEnvFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: .
      Handler: bootstrap
      Runtime: provided.al2
      Architectures:
        - amd64
```

The `Transform` section tells CloudFormation to use the AWS SAM transform to process the template.

After updating the `template.yaml` file, run the `sam deploy --guided` command again:

```zsh
sam deploy --guided
```

This should resolve the error and allow the deployment process to proceed successfully.