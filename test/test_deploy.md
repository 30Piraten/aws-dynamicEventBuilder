sam deploy --guided

Configuring SAM deploy
======================

        Looking for config file [samconfig.toml] :  Not found

        Setting default arguments for 'sam deploy'
        =========================================
        Stack Name [sam-app]: proenv-app
        AWS Region [us-east-1]: 
        #Shows you resources changes to be deployed and require a 'Y' to initiate deploy
        Confirm changes before deploy [y/N]: y
        #SAM needs permission to be able to create roles to connect to the resources in your template
        Allow SAM CLI IAM role creation [Y/n]: Y
        #Preserves the state of previously provisioned resources when an operation fails
        Disable rollback [y/N]: y
        Save arguments to configuration file [Y/n]: Y
        SAM configuration file [samconfig.toml]: 
        SAM configuration environment [default]: 

        Looking for resources needed for deployment:
        Creating the required resources...


- managed s3 Bucket: aws-sam-cli-managed-default-samclisourcebucket-dty26ebljwgz

sam package output-template-file packaged.yaml --s3-bucket aws-sam-cli-managed-default-samclisourcebucket-dty26ebljwgz
File with same data already exists at d41d8cd98f00b204e9800998ecf8427e, skipping upload                                                                                         
Resources:
  ProvisionEnvFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: s3://aws-sam-cli-managed-default-samclisourcebucket-dty26ebljwgz/d41d8cd98f00b204e9800998ecf8427e
      Handler: bootstrap
      Runtime: provided.al2
      Architectures:
      - amd64
    Metadata:
      SamResourceId: ProvisionEnvFunction