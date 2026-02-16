#!/usr/bin/env bash
# Run Terraform destroy with same Docker API version (needed if apply used Docker build).
# Usage: ./scripts/terraform-destroy.sh   or   ./scripts/terraform-destroy.sh -auto-approve
set -e
cd "$(dirname "$0")/.."
export DOCKER_API_VERSION=1.44
cd terraform
exec terraform destroy "$@"
