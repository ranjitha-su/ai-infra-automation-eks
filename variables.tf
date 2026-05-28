variable "external_aws_k8s_admin_principal_arn" {
  description = "ARN of the IAM user or role to set as the principal for the external-aws-k8s-admin role"
  type        = string
}

variable "external_aws_k8s_developer_principal_arn" {
  description = "ARN of the IAM user or role to set as the principal for the external-aws-k8s-developer role"
  type        = string
}

variable "external_aws_k8s_developer_namespaces" {
  description = "List of Kubernetes namespaces the developer role is granted access to"
  type        = list(string)
}
