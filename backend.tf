terraform {
  backend "s3" {
    bucket         = "rj-eks-cluster-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}
