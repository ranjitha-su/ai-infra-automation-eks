resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
}

resource "kubernetes_secret" "argocd_repo" {
  metadata {
    name      = "argocd-repo"
    namespace = helm_release.argocd.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.argocd_repo_url
    username = var.argocd_repo_username
    password = var.argocd_repo_password
  }
}

