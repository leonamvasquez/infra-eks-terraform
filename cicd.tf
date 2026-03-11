# ==============================================================================
# CI/CD (CodeCommit, CodeBuild, CodePipeline)
# ==============================================================================

# --- CodeCommit Repository ---
resource "aws_codecommit_repository" "main" {
  repository_name = "${local.name_prefix}-app"
  description     = "Main application repository for ${var.project}"

  tags = { Name = "${local.name_prefix}-codecommit" }
}

# --- CodeBuild Projects ---
resource "aws_codebuild_project" "build" {
  name          = "${local.name_prefix}-build"
  description   = "Build Docker images"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "${local.name_prefix}/api-service"
    }

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = local.eks_cluster_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
    }
  }

  vpc_config {
    vpc_id             = aws_vpc.main.id
    subnets            = local.private_app_subnet_ids
    security_group_ids = [aws_security_group.internal.id]
  }

  tags = { Name = "${local.name_prefix}-codebuild-build" }
}

resource "aws_codebuild_project" "test" {
  name          = "${local.name_prefix}-test"
  description   = "Run tests"
  build_timeout = 20
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-test.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "test"
    }
  }

  tags = { Name = "${local.name_prefix}-codebuild-test" }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.name_prefix}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-codebuild-logs" }
}

# --- CodePipeline ---
# INTENTIONAL_MISCONFIG: MEDIUM - Pipeline without encryption key
resource "aws_codepipeline" "main" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.main.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Test"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.test.name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
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
        NotificationArn = aws_sns_topic.deployments.arn
        CustomData      = "Review and approve deployment to ${var.environment}"
      }
    }
  }

  tags = { Name = "${local.name_prefix}-pipeline" }
}
