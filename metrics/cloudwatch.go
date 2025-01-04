package metrics

import (
	"context"
	"fmt"

	"github.com/30Piraten/aws-dynamicEventBuilder/logging"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
)

// TODO: MAKE USE OF DRY

// PublishProvisioningMetric publishes a custom metric for
// instance provisioning.
func PublishProvisioningMetric(ctx context.Context) {

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		logging.LogError("Failed to load AWS config:", fmt.Errorf("%s", err))
	}

	// Initialise CloudWatch client
	cloudWatchClient := cloudwatch.NewFromConfig(cfg)

	_, ok := cloudWatchClient.PutMetricData(context.TODO(), &cloudwatch.PutMetricDataInput{
		Namespace: aws.String("EC2ProvisionMetrics"),
		MetricData: []types.MetricDatum{
			{
				MetricName: aws.String("InstancesProvisioned"),
				Unit:       types.StandardUnitCount,

				// Allows the increment of provisioning by 1
				Value: aws.Float64(1),
			},
		},
	})

	if ok != nil {
		logging.LogError("Failed to publish provisioning metric: ", ok)
	} else {
		logging.LogInfo("Published provisioning metric to CloudWatch")
	}
}

// PublishTerminationMetric publishes a custom metric for instance termination
func PublishTerminationMetric(ctx context.Context) {

	config, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		logging.LogError("Failed to load AWS config:", fmt.Errorf("%s", err))
	}

	// Initialise CloudWatch client
	cloudWatchClient := cloudwatch.NewFromConfig(config)

	_, ok := cloudWatchClient.PutMetricData(context.TODO(), &cloudwatch.PutMetricDataInput{
		Namespace: aws.String("EC2ProvisioningMetrics"),
		MetricData: []types.MetricDatum{
			{
				MetricName: aws.String("InstancesTerminated"),
				Unit:       types.StandardUnitCount,

				// Every termination increases by 1
				Value: aws.Float64(1),
			},
		},
	})

	if ok != nil {
		logging.LogError("Failed to publish termination metric: ", ok)
	} else {
		logging.LogInfo("Published termination metric to CloudWatch")
	}
}
