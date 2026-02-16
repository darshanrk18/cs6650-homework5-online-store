#!/usr/bin/env bash
# Get the public IP of the running ECS task (Fargate with assign_public_ip).
# Run from repo root after: cd terraform && terraform apply -auto-approve
# Usage: ./scripts/get-public-url.sh   (or run from terraform/: bash ../scripts/get-public-url.sh)
set -e
TERRAFORM_DIR="${TERRAFORM_DIR:-terraform}"
if [[ ! -d "$TERRAFORM_DIR" ]]; then
  echo "Run from repo root (or set TERRAFORM_DIR). Expected directory: $TERRAFORM_DIR"
  exit 1
fi
cd "$TERRAFORM_DIR"
CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || true)
SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || true)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")
if [[ -z "$CLUSTER" || -z "$SERVICE" ]]; then
  echo "Run 'terraform apply' first and ensure ecs_cluster_name and ecs_service_name outputs exist."
  exit 1
fi
# Prefer RUNNING; if only PENDING, task is still starting
TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status RUNNING --region "$REGION" --query 'taskArns[0]' --output text 2>/dev/null || true)
if [[ -z "$TASK_ARN" || "$TASK_ARN" == "None" ]]; then
  PENDING=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status PENDING --region "$REGION" --query 'taskArns[0]' --output text 2>/dev/null || true)
  if [[ -n "$PENDING" && "$PENDING" != "None" ]]; then
    echo "Task is still starting (PENDING). Wait about 1 minute, then run again: ./scripts/get-public-url.sh"
  else
    echo "No running task found. Wait for the ECS service to start a task (1–2 min after apply), then run again."
    echo "Check ECS console: cluster $CLUSTER, service $SERVICE."
    # Show why the last task stopped (if any)
    STOPPED_ARN=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --desired-status STOPPED --region "$REGION" --max-items 1 --query 'taskArns[0]' --output text 2>/dev/null || true)
    if [[ -n "$STOPPED_ARN" && "$STOPPED_ARN" != "None" ]]; then
      echo ""
      echo "Last stopped task:"
      aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$STOPPED_ARN" --region "$REGION" \
        --query 'tasks[0].{stoppedReason:stoppedReason,stopCode:stopCode,containers:containers[0].{reason:reason,exitCode:exitCode}}' --output table 2>/dev/null || true
      echo ""
      echo "If you fixed the image (e.g. rebuilt with --platform linux/amd64), force a new deployment:"
      echo "  aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment --region $REGION"
    fi
  fi
  exit 1
fi
ENI_ID=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" --region "$REGION" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text 2>/dev/null || true)
if [[ -z "$ENI_ID" || "$ENI_ID" == "None" ]]; then
  echo "Could not get network interface for task."
  exit 1
fi
PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" --region "$REGION" \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text 2>/dev/null || true)
if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "None" ]]; then
  echo "No public IP found for this task."
  exit 1
fi
echo "Product API base URL: http://${PUBLIC_IP}:8080"
echo "Example (pretty JSON): curl -s http://${PUBLIC_IP}:8080/products | jq"
