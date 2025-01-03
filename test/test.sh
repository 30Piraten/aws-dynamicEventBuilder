curl -X POST -H "Content-Type: application/json" \
-d '{
  "environment": "dev",
  "region": "us-east-1",
  "ec2": {
    "instance_type": "t2.micro",
    "ami": "ami-12345678",
    "key_name": "my-key",
    "subnet_id": "subnet-abc123",
    "tags": {"Project": "TestProject"}
  },
  "ttl": 12
}' \
https://<api_gateway_id>.execute-api.<region>.amazonaws.com/<stage>/provision
