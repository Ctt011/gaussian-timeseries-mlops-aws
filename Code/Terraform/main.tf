######################################
# VARIABLES
######################################
variable "account_id" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "github_owner" {}
variable "github_repo" {}
variable "github_token" {}

######################################
# S3 BUCKET + UPLOAD FILE
######################################
resource "aws_s3_bucket" "gaussian_bucket" {
  bucket = "gaussian-bucket-new-repo-terraform-026"
}

resource "aws_s3_bucket_object" "data_file" {
  bucket = aws_s3_bucket.gaussian_bucket.bucket
  key    = "CallCenterData.csv"
  source = "${path.module}/CallCenterData.csv"
  acl    = "private"
}

######################################
# ECR REPOSITORY
######################################
resource "aws_ecr_repository" "gaussian_repo" {
  name                 = "flask-container-staging"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

######################################
# LIGHTSAIL CONTAINER SERVICES
######################################
resource "null_resource" "staging_service" {
  provisioner "local-exec" {
    command = "aws lightsail create-container-service --service-name flask-service-staging --power small --scale 1 --region us-east-1"
  }
}

resource "null_resource" "production_service" {
  provisioner "local-exec" {
    command = "aws lightsail create-container-service --service-name flask-service-prod --power small --scale 1 --region us-east-1"
  }
}


######################################
# SNS TOPIC
######################################
resource "aws_sns_topic" "approval_notification" {
  name         = "approval-notification"
  display_name = "Approval Notification"
}

resource "aws_sns_topic_subscription" "approval_notification_email" {
  topic_arn = aws_sns_topic.approval_notification.arn
  protocol  = "email"
  endpoint  = ""
}

######################################
# LOCALS
######################################
locals {
  s3_bucket_name         = aws_s3_bucket.gaussian_bucket.bucket
  s3_key_name            = aws_s3_bucket_object.data_file.key
  approval_sns_arn       = aws_sns_topic.approval_notification.arn
  staging_lightsail_name = "flask-service-staging"
}

######################################
# IAM ROLES — CODEBUILD (STAGING)
######################################
resource "aws_iam_role" "codebuild_staging_role" {
  name = "codebuild-staging-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_staging_policy" {
  name = "codebuild-staging-policy"
  role = aws_iam_role.codebuild_staging_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:*", "ecr:*", "lightsail:*"], Resource = "*" },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource = "*"
      }
    ]
  })
}

######################################
# CODEBUILD PROJECT (STAGING)
######################################
resource "aws_codebuild_project" "staging_build" {
  name         = "staging-build"
  service_role = aws_iam_role.codebuild_staging_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_REGION"
      value = "us-east-1"
    }
    environment_variable {
      name  = "S3_BUCKET"
      value = local.s3_bucket_name
    }
    environment_variable {
      name  = "S3_KEY"
      value = local.s3_key_name
    }
    environment_variable {
      name  = "ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "AWS_ACCESS_KEY_ID"
      value = var.aws_access_key_id
    }
    environment_variable {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = var.aws_secret_access_key
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-staging.yaml"
  }
}

######################################
# IAM ROLES — CODEBUILD (PROD)
######################################
resource "aws_iam_role" "codebuild_prod_role" {
  name = "codebuild-prod-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_prod_policy" {
  name = "codebuild-prod-policy"
  role = aws_iam_role.codebuild_prod_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:*", "ecr:*", "lightsail:*"], Resource = "*" },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource = "*"
      }
    ]
  })
}

######################################
# CODEBUILD PROJECT (PROD)
######################################
resource "aws_codebuild_project" "prod_build" {
  name         = "prod-build"
  service_role = aws_iam_role.codebuild_prod_role.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_REGION"
      value = "us-east-1"
    }
    environment_variable {
      name  = "S3_BUCKET"
      value = local.s3_bucket_name
    }
    environment_variable {
      name  = "S3_KEY"
      value = local.s3_key_name
    }
    environment_variable {
      name  = "ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "AWS_ACCESS_KEY_ID"
      value = var.aws_access_key_id
    }
    environment_variable {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = var.aws_secret_access_key
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-prod.yaml"
  }
}

######################################
# IAM ROLE — CODEPIPELINE
######################################
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "codepipeline_policy1" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy2" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# Inline policy with CodeConnections + S3 + CodeBuild
resource "aws_iam_role_policy" "codepipeline_inline_policy" {
  name = "codepipeline-inline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = [aws_s3_bucket.gaussian_bucket.arn, 
        "${aws_s3_bucket.gaussian_bucket.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ],
        Resource = "*"
      }
    ]
  })
}

######################################
# CODEPIPELINE — 4 STAGES
######################################
resource "aws_codepipeline" "pipeline" {
  depends_on = [
    aws_s3_bucket.gaussian_bucket,
    aws_codebuild_project.staging_build,
    aws_codebuild_project.prod_build,
    null_resource.staging_service,
    null_resource.production_service
  ]

  name     = "lightsail-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = local.s3_bucket_name
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = "master"
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build_Staging"
    action {
      name             = "Build_Staging"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["staging_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.staging_build.name
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData      = "Check deployment in the Staging Environment and approve it for deployment to production."
        NotificationArn = local.approval_sns_arn
      }
    }
  }

  stage {
    name = "DeploytoProd"
    action {
      name            = "DeploytoProd"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["staging_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.prod_build.name
      }
    }
  }
}
