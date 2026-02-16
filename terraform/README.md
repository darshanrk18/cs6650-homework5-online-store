# Terraform — ECR + ECS Fargate for Product API

From **terraform** directory (or repo root with `cd terraform`):

```bash
terraform init -upgrade
terraform apply -auto-approve
```

The image is built with `--platform linux/amd64` for ECS Fargate (required on Apple Silicon). Build/push uses your local Docker CLI (`local-exec`). Ensure Docker is running.

Get the API URL: from repo root run `./scripts/get-public-url.sh`.

Clean up: `terraform destroy -auto-approve`.
