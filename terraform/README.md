# Terraform — ECR + ECS Fargate + ALB (HW6 Part 3)

From **terraform** directory (or repo root with `cd terraform`):

```bash
terraform init -upgrade
terraform apply -auto-approve
```

The image is built with `--platform linux/amd64` for ECS Fargate (required on Apple Silicon). Build/push uses your local Docker CLI (`local-exec`). Ensure Docker is running.

**Part 3 (ALB):** Traffic goes through the ALB. For load testing use the ALB URL:

```bash
terraform output alb_url
# Use this as Locust host (e.g. http://product-api-alb-xxxx.elb.amazonaws.com)
```

**Task URL (direct):** From repo root, `./scripts/get-public-url.sh` (for debugging; Part 3 uses ALB).

**Clean up:** `terraform destroy -auto-approve`.
