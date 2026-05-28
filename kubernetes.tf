resource "kubernetes_namespace_v1" "online_boutique" {
  metadata {
    name = "online-boutique"
  }

  depends_on = [module.eks]
}
