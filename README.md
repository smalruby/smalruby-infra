# Smalruby Infrastructure

Infrastructure as Code for Smalruby APIs using AWS CloudFormation.

## Overview

This repository contains AWS CloudFormation templates and related infrastructure configurations for managing Smalruby APIs, including:

- scratch-api-proxy: Proxy for calling Scratch APIs that cannot be called directly due to CORS restrictions
- cors-proxy: General-purpose proxy for various URLs with CORS issues

## Structure

- `templates/`: CloudFormation templates
- `scripts/`: Deployment and utility scripts
- `tests/`: Infrastructure tests

## Deployment

(Documentation will be added as implementation progresses)