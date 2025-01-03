package dynamotable

import (
	"context"
	"fmt"

	"github.com/30Piraten/aws-dynamicEventBuilder/logging"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
	"github.com/aws/aws-sdk-go/aws"
)

// getTableName returns the DynamoDB table name for the given environment and table type
func getTableName(env string, tableType string) (string, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return "", fmt.Errorf("failed to load AWS config: %w", err)
	}

	ssmClient := ssm.NewFromConfig(cfg)

	paramName := fmt.Sprintf("/project-r3/%s/dynamodb/%s-table-name", env, tableType)

	param, err := ssmClient.GetParameter(context.TODO(), &ssm.GetParameterInput{
		Name:           aws.String(paramName),
		WithDecryption: aws.Bool(false),
	})
	if err != nil {
		return "", fmt.Errorf("failed to retrieve parameter value %s: %w", paramName, err)
	}

	return aws.StringValue(param.Parameter.Value), nil
}

// result := getTableName("dev", "dynamodb")

func TableName(environment string, tableType string) (string, error) {

	tableName, err := getTableName(environment, tableType)
	if err != nil {
		logging.LogError("Failed to get DynamoDB table names", err)
		return "", err
	}

	return tableName, nil
}
