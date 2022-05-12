###################Install Istio (Service Mesh) #######################################

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_secret" "grafana" {

  metadata {
    name      = "grafana"
    namespace = "istio-system"
    labels = {
      app = "grafana"
    }
  }
  data = {
    username   = "admin"
    passphrase = var.istio_password
  }
  type       = "Opaque"
  depends_on = [kubernetes_namespace.istio_system]
}

resource "kubernetes_secret" "kiali" {

  metadata {
    name      = "kiali"
    namespace = "istio-system"
    labels = {
      app = "kiali"
    }
  }
  data = {
    username   = "admin"
    passphrase = var.istio_password
  }
  type       = "Opaque"
  depends_on = [kubernetes_namespace.istio_system]
}

resource "local_file" "istio-config" {
  content = templatefile("${path.module}/templates/istio-aks.tmpl", {
    enableGrafana = false
    enableKiali   = false
    enableTracing = false
  })
  filename = "istio-aks.yaml"
}

resource "null_resource" "istio" {
  provisioner "local-exec" {
    command = "yes | ~/.istioctl/bin/istioctl install --kubeconfig \"${var.kubeconfig_path}\""
  }
  depends_on = [kubernetes_secret.grafana, kubernetes_secret.kiali, local_file.istio-config]
}