resource "aws_iam_role" "external_aws_k8s_developer" {
  name = "external-aws-k8s-developer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = var.external_aws_k8s_developer_principal_arn }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "external_aws_k8s_admin" {
  name = "external-aws-k8s-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = var.external_aws_k8s_admin_principal_arn }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}
