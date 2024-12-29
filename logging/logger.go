package logging

import (
	"os"

	"github.com/sirupsen/logrus"
)

var logger = logrus.New()

func Init() {
	// Set log format to JSON for structured logging
	logger.SetFormatter(&logrus.JSONFormatter{
		PrettyPrint: true,
	})

	// Set log level (info for production, debug for development)
	logger.SetLevel(logrus.InfoLevel)
	if os.Getenv("DEBUG") == "true" {
		logger.SetLevel(logrus.DebugLevel)
	}
}

func LogError(msg string, err error) {
	logger.WithFields(logrus.Fields{
		"error": err.Error(),
	}).Error(msg)
}

func LogInfo(msg string) {
	logger.Info(msg)
}
