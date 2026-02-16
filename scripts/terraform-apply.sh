#!/usr/bin/env bash
# Run Terraform apply with Docker API version set (avoids "client version 1.41 is too old" on newer Docker).
# Usage: ./scripts/terraform-apply.sh   or   ./scripts/terraform-apply.sh -auto-approve
set -e
cd "$(dirname "$0")/.."
export DOCKER_API_VERSION=1.44
cd terraform
exec terraform apply "$@"
