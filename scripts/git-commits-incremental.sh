#!/usr/bin/env bash
# Incremental commits for Terraform + scripts + README. Run from repo root.
set -e
cd "$(dirname "$0")/.."

echo "Commit 1: Terraform"
git add terraform/
git commit -m "feat: add Terraform for ECR/ECS Fargate (local-exec build, linux/amd64)" || true

echo "Commit 2: Scripts"
git add scripts/get-public-url.sh scripts/terraform-apply.sh scripts/terraform-destroy.sh scripts/git-commits-incremental.sh
git commit -m "chore: add get-public-url, terraform-apply, terraform-destroy, git-commits-incremental scripts" || true

echo "Commit 3: README"
git add README.md
git commit -m "docs: update README (Part III Terraform, region, get-public-url, jq example)" || true

echo "Done. Push with: git push origin main"
