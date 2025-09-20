#!/bin/bash

# Local testing script for Smalruby infrastructure
# This script starts SAM local API for testing

set -e

echo "Starting SAM local API for testing..."
echo "This will start a local API Gateway on http://127.0.0.1:3000"
echo ""

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "Error: SAM CLI is not installed."
    echo "Please install SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html"
    exit 1
fi

# Build first if needed
if [ ! -d ".aws-sam" ]; then
    echo "Building SAM application first..."
    sam build
fi

# Start local API
echo "Starting local API..."
echo "Available endpoints will be:"
echo "  GET  http://127.0.0.1:3000/cors-proxy"
echo "  GET  http://127.0.0.1:3000/mesh-domain"
echo "  GET  http://127.0.0.1:3000/scratch-api-proxy/translate"
echo "  GET  http://127.0.0.1:3000/scratch-api-proxy/projects/{projectId}"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

sam local start-api --host 0.0.0.0 --port 3000