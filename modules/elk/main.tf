resource "kubernetes_manifest" "namespace_grafana" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "elk_quickstart"
    }
  }
}

resource "kubernetes_manifest" "elasticsearch_quickstart" {
  depends_on = [kubernetes_manifest.namespace_grafana]
  manifest = {
    "apiVersion" = "elasticsearch.k8s.elastic.co/v1"
    "kind" = "Elasticsearch"
    "metadata" = {
      "name" = "quickstart"
      "namespace" = "elk_quickstart"
    }
    "spec" = {
      "nodeSets" = [
        {
          "config" = {
            "node.store.allow_mmap" = false
          }
          "count" = 1
          "name" = "default"
        },
      ]
      "version" = "8.2.1"
    }
  }
}

resource "kubernetes_manifest" "kibana_quickstart" {
  depends_on = [kubernetes_manifest.namespace_grafana]
  manifest = {
    "apiVersion" = "kibana.k8s.elastic.co/v1"
    "kind" = "Kibana"
    "metadata" = {
      "name" = "quickstart"
      "namespace" = "elk_quickstart"
    }
    "spec" = {
      "count" = 1
      "elasticsearchRef" = {
        "name" = "quickstart"
      }
      "http" = {
        "tls" = {
          "selfSignedCertificate" = {
            "disabled" = true
          }
        }
      }
      "version" = "8.2.1"
    }
  }
}