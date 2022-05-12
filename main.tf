module "nginx_ingress" {
  source             = "./modules/nginx_ic"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
}

module "istio" {
  source             = "./modules/istio"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
  istio_password     = var.istio_password
}