# Wire modules: network, ECR, logging, ECS. Build Product API image and push to ECR.

module "network" {
  source         = "./modules/network"
  service_name   = var.service_name
  container_port = var.container_port
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.ecr_repository_name
}

module "logging" {
  source            = "./modules/logging"
  service_name      = var.service_name
  retention_in_days = var.log_retention_days
}

# Learner's Lab provides LabRole for ECS tasks
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Build and push image for linux/amd64 (required for ECS Fargate) using local Docker CLI
resource "null_resource" "build_and_push" {
  triggers = {
    repo_url = module.ecr.repository_url
    platform = "linux/amd64"
  }
  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      docker build --platform linux/amd64 -t ${module.ecr.repository_url}:latest ..
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${regex("^[^/]+", module.ecr.repository_url)}
      docker push ${module.ecr.repository_url}:latest
    EOT
    working_dir = path.module
  }
  depends_on = [module.ecr]
}

module "ecs" {
  source             = "./modules/ecs"
  service_name       = var.service_name
  image              = "${module.ecr.repository_url}:latest"
  container_port     = var.container_port
  subnet_ids         = module.network.subnet_ids
  security_group_ids = [module.network.security_group_id]
  execution_role_arn = data.aws_iam_role.lab_role.arn
  task_role_arn      = data.aws_iam_role.lab_role.arn
  log_group_name     = module.logging.log_group_name
  ecs_count          = var.ecs_count
  region             = var.aws_region
  depends_on         = [null_resource.build_and_push]
}
