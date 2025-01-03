# ProvisionEnv Function
cd monitordrift/
GOOS=linux GOARCH=amd64 go build -o main monitor.go
zip monitor_drift_payload.zip monitor.go
cd -