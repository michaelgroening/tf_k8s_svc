module "nginx_ingress" {
  source             = "./modules/nginx_ic"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
}

module "prometheus" {
  source             = "./modules/prometheus"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
}

module "grafana" {
  source             = "./modules/grafana"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
}

module "loki" {
  source             = "./modules/loki"
  kubeconfig_path    = var.kubeconfig_path
  cluster_name       = var.cluster_name
}
