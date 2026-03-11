# ==============================================================================
# ECR Repositories
# ==============================================================================

resource "aws_ecr_repository" "main" {
  for_each = toset(local.ecr_repositories)

  name                 = "${local.name_prefix}/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ebs.arn
  }

  tags = { Name = "${local.name_prefix}-${each.value}" }
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = toset(local.ecr_repositories)

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# INTENTIONAL_MISCONFIG: MEDIUM - ECR repository with mutable tags
resource "aws_ecr_repository" "dev" {
  name                 = "${local.name_prefix}/dev-tools"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = { Name = "${local.name_prefix}-dev-tools" }
}

resource "aws_ecr_replication_configuration" "main" {
  replication_configuration {
    rule {
      destination {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}
