#!/bin/bash

# Deploy Smalruby infrastructure using AWS SAM
# This script handles building and deploying the SAM application

set -e

# Configuration
STACK_NAME="smalruby-infrastructure"
S3_BUCKET_PREFIX="smalruby-sam-deployment"
REGION="ap-northeast-1"
STAGE="prod"

# Generate unique S3 bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET="${S3_BUCKET_PREFIX}-${ACCOUNT_ID}-${REGION}"

echo "Deploying Smalruby infrastructure..."
echo "Stack Name: $STACK_NAME"
echo "S3 Bucket: $S3_BUCKET"
echo "Region: $REGION"
echo "Stage: $STAGE"
echo ""

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "Error: SAM CLI is not installed."
    echo "Please install SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html"
    exit 1
fi

# Create S3 bucket if it doesn't exist
echo "Checking S3 bucket..."
if ! aws s3 ls "s3://$S3_BUCKET" 2>/dev/null; then
    echo "Creating S3 bucket: $S3_BUCKET"
    aws s3 mb "s3://$S3_BUCKET" --region "$REGION"
else
    echo "S3 bucket already exists: $S3_BUCKET"
fi

# Build SAM application
echo "Building SAM application..."
sam build

# Deploy SAM application
echo "Deploying SAM application..."
sam deploy \
    --stack-name "$STACK_NAME" \
    --s3-bucket "$S3_BUCKET" \
    --region "$REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        Stage="$STAGE" \
    --confirm-changeset

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Stack outputs:"
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output table