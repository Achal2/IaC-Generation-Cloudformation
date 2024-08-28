# Source Code Management
module "cloud9" {
  source = "terraform-aws-modules/cloud9/aws"

  # Cloud9 Environment settings
}

module "codecommit" {
  source = "terraform-aws-modules/codecommit/aws"

  # CodeCommit repository settings
}

module "codepipeline" {
  source = "terraform-aws-modules/codepipeline/aws"

  # CodePipeline settings
  artifact_bucket_name = aws_s3_bucket.artifact_bucket.id
  codebuild_project_name = module.codebuild.project_name
  codecommit_repo_name = module.codecommit.repo_name
}

module "codebuild" {
  source = "terraform-aws-modules/codebuild/aws"

  # CodeBuild project settings
  buildspec = file("buildspec.yml")
}

# Web Application
module "client" {
  source = "./modules/client"

  # Client application settings
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  # API Gateway settings
  integrations = {
    "ANY /" = {
      lambda_arn             = module.lambda.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }
}

module "lambda" {
  source = "terraform-aws-modules/lambda/aws"

  # Lambda function settings
  function_name = "ProcessRecords"
  handler = "index.handler"
  runtime = "nodejs14.x"
  source_path = "./lambda"
}

module "app_service" {
  source = "terraform-aws-modules/ecs/aws//modules/fargate"

  # Fargate service settings
  name = "app-service"
  container_insights = true
  task_container_command = ["node", "app.js"]
  task_container_port = 3000
  desired_count = 2
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100
  health_check_path = "/health"
}

# Authentication and Authorization
module "cognito_userpool" {
  source = "terraform-aws-modules/cognito-user-pool/aws"

  # Cognito User Pool settings
  user_pool_name = "app-user-pool"
  email_verification_subject = "Verify your email for our awesome app!"
  email_verification_message = "Please use the link below to verify your email address. Thanks!"
}

module "cognito_identity_pool" {
  source = "terraform-aws-modules/cognito-identity-pool/aws"

  # Cognito Identity Pool settings
  identity_pool_name = "app-identity-pool"
  allow_unauthenticated_identities = false
  cognito_user_pools = [module.cognito_userpool.user_pool_id]
}

# Networking
module "nlb" {
  source = "terraform-aws-modules/alb/aws"

  # Network Load Balancer settings
  name = "app-nlb"
  load_balancer_type = "network"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.private_subnets
  target_groups = [
    {
      name = "app-tg"
      backend_protocol = "TCP"
      backend_port = 3000
      target_type = "ip"
    }
  ]
}

# Data Storage
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  # S3 Bucket settings
  bucket = "app-user-data"
  acl = "private"
  force_destroy = true

  # S3 bucket policies
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy = true
}

module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  # DynamoDB table settings
  name = "app-data"
  hash_key = "UserId"
  billing_mode = "PAY_PER_REQUEST"

  # DynamoDB Streams for CDC
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

module "kinesis_firehose" {
  source = "terraform-aws-modules/kinesis-firehose-extended-s3-bucket/aws"

  # Kinesis Data Firehose settings
  name = "app-user-data-firehose"
  s3_bucket_name = module.s3_bucket.s3_bucket_id
  s3_buffer_size = 5
  s3_buffer_interval = 300
}

# Other Components
module "fargate" {
  source = "terraform-aws-modules/ecs/aws//modules/fargate"

  # Fargate settings
  name = "app-fargate"
  container_insights = true
  task_container_command = ["node", "app.js"]
  task_container_port = 3000
  desired_count = 2
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100
  health_check_path = "/health"
}

# Additional Resources
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  # VPC settings
  name = "app-vpc"
  cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  # Security Group settings
  name = "app-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = ["https-443-tcp"]
  egress_rules = ["all-all"]
}

module "iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  # IAM Role settings
  role_name = "app-role"
  role_requires_mfa = true
  trusted_role_services = ["codebuild.amazonaws.com", "codepipeline.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
  ]
}

