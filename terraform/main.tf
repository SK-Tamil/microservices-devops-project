provider "aws" {
  region = var.aws_region
}

# DevOps EC2 security group
resource "aws_security_group" "devops_sg" {
  name        = "microservices-devops-sg"
  description = "Security group for Jenkins and monitoring"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from existing application EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description     = "Jenkins from existing application EC2"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Microservices-DevOps-SG"
  }
}

# IAM role for DevOps EC2
resource "aws_iam_role" "devops_role" {
  name = "Microservices-DevOps-EC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# ECR push and pull permissions
resource "aws_iam_role_policy" "ecr_policy" {
  name = "Microservices-ECR-Push-Pull"
  role = aws_iam_role.devops_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = [
          aws_ecr_repository.user_service.arn,
          aws_ecr_repository.product_service.arn,
          aws_ecr_repository.order_service.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "devops_profile" {
  name = "Microservices-DevOps-Instance-Profile"
  role = aws_iam_role.devops_role.name
}

# ECR repositories
resource "aws_ecr_repository" "user_service" {
  name                 = "user-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "product_service" {
  name                 = "product-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "order_service" {
  name                 = "order-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# DevOps EC2 instance
resource "aws_instance" "devops" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.devops_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "Microservices-DevOps-Server"
  }
}

# Allow DevOps EC2 to SSH into the existing application EC2
resource "aws_security_group_rule" "app_ssh_from_devops" {
  type                     = "ingress"
  security_group_id        = var.app_security_group_id
  source_security_group_id = aws_security_group.devops_sg.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "SSH from DevOps EC2"
}
