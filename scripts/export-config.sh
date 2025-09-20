#!/bin/bash

# Export existing AWS configurations for Smalruby infrastructure
# This script exports API Gateway and Lambda function configurations

set -e

# Configuration
API_GATEWAY_ID="drgkdd00la"
STAGE_NAME="prod"
EXPORT_DIR="$(dirname "$0")/../exported-configs"

# Lambda function names
LAMBDA_FUNCTIONS=(
    "smalruby-cors-proxy"
    "smalruby-mesh-zone-get"
    "smalruby-scratch-api-proxy-translate"
    "smalruby-scratch-api-proxy-get-project-info"
    "cors-for-smalruby"
)

echo "Exporting Smalruby infrastructure configurations..."

# Create export directory
mkdir -p "$EXPORT_DIR"

# Export API Gateway configurations
echo "Exporting API Gateway configurations..."
aws apigateway get-export \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name "$STAGE_NAME" \
    --export-type swagger \
    --accepts application/json \
    "$EXPORT_DIR/api-gateway-swagger.json"

aws apigateway get-resources \
    --rest-api-id "$API_GATEWAY_ID" \
    > "$EXPORT_DIR/api-gateway-resources.json"

aws apigateway get-stage \
    --rest-api-id "$API_GATEWAY_ID" \
    --stage-name "$STAGE_NAME" \
    > "$EXPORT_DIR/api-gateway-stage-$STAGE_NAME.json"

# Export Lambda function configurations
echo "Exporting Lambda function configurations..."
for function_name in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "Exporting $function_name..."
    aws lambda get-function \
        --function-name "$function_name" \
        > "$EXPORT_DIR/lambda-$function_name.json"
done

echo "Export completed. Files saved to: $EXPORT_DIR"
echo ""
echo "Exported files:"
ls -la "$EXPORT_DIR"