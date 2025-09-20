# Smalruby Infrastructure

Infrastructure as Code for Smalruby APIs using AWS SAM (Serverless Application Model).

## Overview

This repository contains AWS SAM templates and related infrastructure configurations for managing Smalruby APIs, including:

- **cors-proxy**: General-purpose proxy for various URLs with CORS issues
- **scratch-api-proxy**: Proxy for calling Scratch APIs that cannot be called directly due to CORS restrictions
- **mesh-zone**: Generate identity from gateway IPv4 address for Smalruby Mesh

## Structure

- `template.yaml`: Main SAM template defining API Gateway and Lambda functions
- `lambda/`: Lambda function source code directories
- `scripts/`: Deployment and utility scripts
- `exported-configs/`: Exported configurations from existing AWS resources
- `samconfig.toml`: SAM configuration file

## Lambda Functions

1. **smalruby-cors-proxy**: General-purpose CORS proxy
2. **smalruby-mesh-zone-get**: Mesh zone domain generation
3. **smalruby-scratch-api-proxy-translate**: Scratch translate API proxy
4. **smalruby-scratch-api-proxy-get-project-info**: Scratch project info API proxy
5. **cors-for-smalruby**: CORS handler for Smalruby

## Prerequisites

- AWS CLI configured with appropriate credentials
- SAM CLI installed
- Ruby 3.4 runtime (for local testing)

## Installation

### Install SAM CLI

```bash
# macOS
brew install aws-sam-cli

# Or pip
pip install aws-sam-cli
```

## Usage

### Local Testing

ローカルでLambda関数をテストするには、[LOCAL_TESTING.md](./LOCAL_TESTING.md)を参照してください。

```bash
# 個別の関数をテスト
./test-local.sh CorsForSmalrubyFunction

# すべての関数をテスト
./test-all-local.sh

# ローカルAPI Gatewayを起動
./start-local-api.sh

# API エンドポイントをテスト
./test-api-endpoints.sh
```

### Export Existing Configurations

```bash
./scripts/export-config.sh
```

### Local Development and Testing

```bash
# Build the application
sam build

# Start local API for testing
./scripts/local-test.sh
# or
sam local start-api

# Test specific function
sam local invoke SmalrubyCorsProxyFunction --event events/cors-proxy-event.json
```

### Deployment

```bash
# Deploy to AWS
./scripts/deploy.sh
# or
sam build && sam deploy
```

### API Endpoints

After deployment, the following endpoints will be available:

- `GET /cors-proxy` - General CORS proxy
- `GET /mesh-domain` - Mesh zone domain generation
- `GET /scratch-api-proxy/translate` - Scratch translate proxy
- `GET /scratch-api-proxy/projects/{projectId}` - Scratch project info proxy

## Configuration

- **Stack Name**: `smalruby-infrastructure`
- **Region**: `ap-northeast-1` (Tokyo)
- **Stage**: `prod`
- **Domain**: `api.smalruby.app`

## Development Notes

- Lambda functions are currently placeholder implementations
- Actual function code should be retrieved from existing Lambda functions
- All functions use Ruby 3.4 runtime with ARM64 architecture
- CORS headers are configured for cross-origin requests