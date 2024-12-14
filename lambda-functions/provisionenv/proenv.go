package provisionenv

import (
  "context"
  "fmt"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/aws/aws-sdk-go/aws"
  "github.com/aws/aws-sdk-go/aws/session"
  "github.com/aws/aws-sdk-go/service/ec2"
)

func HandleRequest(ctx context.Context) (string, error) {
  sess := session.Must(session.NewSession())
  svc := ec2.New(sess)

  input := &ec2.RunInstancesInput{
    ImageId:      aws.String("ami-0c55b159cbfafe1f0"),  # Replace with a valid AMI ID
    InstanceType: aws.String("t2.micro"),
    MinCount:     aws.Int64(1),
    MaxCount:     aws.Int64(1),
  }

  _, err := svc.RunInstances(input)
  if err != nil {
    return "", fmt.Errorf("could not create instance: %v", err)
  }

  return "Instance created successfully", nil
}
