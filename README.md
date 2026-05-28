# AI-Assisted DevSecOps: Automated EKS Cluster Provisioning on AWS

Terraform-based infrastructure automation for deploying a production-grade Amazon EKS cluster on AWS, built iteratively using AI-assisted prompt engineering.

## Overview

This project provisions a complete Kubernetes environment on AWS including networking, compute, and access control — entirely through Terraform. The infrastructure is designed around the principle of least privilege, using EKS Access Entries to grant scoped Kubernetes API access to external IAM roles without managing static credentials inside the cluster.

### What gets provisioned

| Resource | Details |
|----------|---------|
| VPC | `10.0.0.0/16`, us-west-2 |
| Subnets | 2 public + 2 private, spread across AZs |
| NAT Gateway | Single, attached to public subnet |
| EKS Cluster | v1.27, managed via `terraform-aws-modules/eks` |
| Managed Node Group | min 1 / desired 2 / max 5 nodes |
| IAM Roles | `external-aws-k8s-admin`, `external-aws-k8s-developer` |
| EKS Access Entries | Cluster-wide view (admin), namespace-scoped view (developer) |
| Kubernetes Namespace | `online-boutique` |

### Access Model

External IAM users have no direct AWS permissions. They assume IAM roles which are registered as EKS Access Entry principals, granting them scoped access to the Kubernetes API only.

```
IAM User → sts:AssumeRole → IAM Role → EKS Access Entry → Kubernetes API
```

| Role | EKS Policy | Scope |
|------|-----------|-------|
| `external-aws-k8s-admin` | `AmazonEKSViewPolicy` | Cluster-wide |
| `external-aws-k8s-developer` | `AmazonEKSViewPolicy` | `online-boutique` namespace |

### IAM Role Setup

This project creates two IAM roles — `external-aws-k8s-admin` and `external-aws-k8s-developer` — and registers them as EKS Access Entry principals, giving them scoped access to the Kubernetes API.

**Who can assume these roles:**
- The trust principal for each role is set via an input variable (`external_aws_k8s_admin_principal_arn`, `external_aws_k8s_developer_principal_arn`)
- Currently configured to trust an **IAM user ARN** as the principal
- Can also be set to an **IAM group ARN**, allowing any member of that group to assume the role

**How cluster access works:**
- A user (or group member) calls `sts:AssumeRole` to assume the relevant role
- AWS returns temporary credentials (access key, secret key, session token)
- Those credentials are used with `kubectl` to interact with the EKS cluster
- Kubernetes API access is scoped by the EKS Access Entry policy attached to that role

**Adding new users to the cluster later:**
- If the principal is an **IAM user** — that user uses their own access keys to assume the role
- If the principal is an **IAM group** — add the new user to the group, and they automatically inherit the ability to assume the role and access the cluster
- No changes to the Terraform config or EKS Access Entries are needed when adding group members

### Usage

```bash
# 1. Fill in terraform.tfvars with principal ARNs
# 2. Initialise providers and modules
terraform init

# 3. Preview changes
terraform plan

# 4. Apply
terraform apply
```

---

## AI Prompt Log

1. **Using terraform, create a vpc with cidr block - 10.0.0.0/16. in us-west-2 region.
   Create 2 private and 2 public subnets in that vpc spread across az with cidrs
   private - [10.0.1.0/24, 10.0.2.0/24]
   public - [10.0.100.0/24, 10.0.101.0/24]
   Create a terraform script for creating an aws eks cluster with
   1 min node, 5 max nodes, 2 desired nodes, single nat gateway.**
2. Remove everything related to IAM for now. I will provide prompts to add them later.
3. **Don't use aws_eks_cluster resource. Instead use the aws eks module to create the cluster with 1 min node, 5 max nodes, 2 desired nodes, single nat gateway.**
4. **Update the eks configuration to allow aws-auth configmap to be managed from the eks config.**
5. **Create an aws iam role - external-aws-k8s-admin. Add this role's arn as the principle arn in the access entry configuration and assign the policy - cluster wide amazoneksadmin to this role.**
6. Move the creation of external_aws_k8s_admin to its own file in iam-roles.tf.
7. I do not want current caller identity to be the principal for external_aws_k8s_admin role. I would like the user arn to be an input variable.
8. Rename the variable to external-aws-k8s-admin-principal-arn.
9. **Create terraform.tfvars file with an option to set external_aws_k8s_admin_principal_arn.**
10. **Create another iam role - external_aws_k8s_developer. Create a principal arn variable with the corresponding name for this role. Add an entry in access entries to allow this role, namespace specific access the view the resources.**
11. **Change the developer access entry to view policy.**
12. **Update the admin access entry to cluster admin view only policy.**
13. **Create a namespace resource with the name online-boutique in the kubernetes cluster.**
14. Background: gitlab pipeline needs to be able to (using Terraform) call aws api to provision a cluster. The following steps need to happen before this project is executed in a pipeline, as the below resources are needed for gitlab pipeline to be able to access AWS APIs. Create a build stage. In this stage, generate a jwt token from gitlab oidc provider. Use that token to assumerolewithwebidentity. The role to be assumed will be set as a ci/cd variable in ROLE_ARN. AWS needs to create a new role - gitlab-ci, this role needs to trust the oidc provider as principal and allow admin full access.
15. Create .gitlab-ci.yml file for pipeline.
16. Move the .gitlab-ci.yml file to ai-infra-automation-eks directory.
17. Use the official amazon/aws-cli image on dockerhub for the build stage. Fix the terraform entrypoint issue for other stages.
18. Move terraform init to its own stage. Don't put it under default.
19. Create a remote backend for the terraform state. 

---

## Testing

### Overview

This section describes how to validate that the Kubernetes RBAC access entries are working correctly for the two IAM roles provisioned by this project.

| IAM User | Assumes Role | EKS Access Policy | Scope |
|----------|-------------|-------------------|-------|
| `aws-k8s-admin` | `external-aws-k8s-admin` | `AmazonEKSViewPolicy` | Cluster-wide |
| `aws-k8s-developer` | `external-aws-k8s-developer` | `AmazonEKSViewPolicy` | Namespace (`online-boutique`) |

> **Note:** Both users have no direct AWS permissions. Their only allowed IAM action is `sts:AssumeRole` on their respective roles.
> In production, these users would typically be federated from an Active Directory via AWS IAM Identity Center rather than created manually.

---

### Prerequisites

- AWS CLI installed and configured
- `kubectl` installed
- `kubeconfig` updated for the cluster:
  ```bash
  aws eks update-kubeconfig --region us-west-2 --name eks-cluster
  ```

---

### Step 1 — Create IAM Users

Manually create two IAM users in the AWS Console or CLI with **no permissions** attached:

```bash
aws iam create-user --user-name aws-k8s-admin
aws iam create-user --user-name aws-k8s-developer
```

Create access keys for each user to use with the CLI:

```bash
aws iam create-access-key --user-name aws-k8s-admin
aws iam create-access-key --user-name aws-k8s-developer
```

The only IAM permission each user needs is the ability to assume their respective role:

```json
{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "<role-arn>"
}
```

---

### Step 2 — Assume the Role and Export Credentials

For each user, use their access key to assume the corresponding role and export the temporary credentials.

**Admin user:**
```bash
aws sts assume-role \
  --role-arn <external-aws-k8s-admin-role-arn> \
  --role-session-name admin-test-session \
  --profile aws-k8s-admin

export AWS_ACCESS_KEY_ID=<AssumedRoleAccessKeyId>
export AWS_SECRET_ACCESS_KEY=<AssumedRoleSecretAccessKey>
export AWS_SESSION_TOKEN=<AssumedRoleSessionToken>
```

**Developer user:**
```bash
aws sts assume-role \
  --role-arn <external-aws-k8s-developer-role-arn> \
  --role-session-name developer-test-session \
  --profile aws-k8s-developer

export AWS_ACCESS_KEY_ID=<AssumedRoleAccessKeyId>
export AWS_SECRET_ACCESS_KEY=<AssumedRoleSecretAccessKey>
export AWS_SESSION_TOKEN=<AssumedRoleSessionToken>
```

---

### Step 3 — Validate Kubernetes Access

#### Admin Role (`aws-k8s-admin`)

| Command | Expected Result |
|---------|----------------|
| `kubectl get pods -A` | **Pass** — lists pods from all namespaces |
| `kubectl delete pod <pod-name> -n <namespace>` | **Forbidden** — `AmazonEKSViewPolicy` does not grant `delete` |
| `kubectl create namespace test-ns` | **Forbidden** — `AmazonEKSViewPolicy` does not grant `create` |

```bash
# Should succeed
kubectl get pods -A

# Should fail with Forbidden
kubectl delete pod <pod-name> -n <namespace>
kubectl create namespace test-ns
```

---

#### Developer Role (`aws-k8s-developer`)

| Command | Expected Result |
|---------|----------------|
| `kubectl get pods -n online-boutique` | **Pass** — access is scoped to this namespace |
| `kubectl get pods -A` | **Forbidden** — no cluster-wide access |
| `kubectl get pods -n kube-system` | **Forbidden** — outside allowed namespace scope |
| `kubectl get nodes` | **Forbidden** — nodes are cluster-scoped resources, not namespaced |

```bash
# Should succeed
kubectl get pods -n online-boutique

# Should fail with Forbidden
kubectl get pods -A
kubectl get pods -n kube-system
kubectl get nodes
```
