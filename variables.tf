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
  default     = ["online-boutique"]
}

variable "argocd_repo_url" {
  description = "URL of the Git repository ArgoCD will sync from"
  type        = string
}

variable "argocd_repo_username" {
  description = "Username for authenticating with the Git repository"
  type        = string
  default     = ""
}

variable "argocd_repo_password" {
  description = "Password or personal access token for authenticating with the Git repository"
  type        = string
  sensitive   = true
  default     = ""
}
