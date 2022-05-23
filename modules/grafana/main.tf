resource "kubernetes_manifest" "namespace_grafana" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "grafana"
    }
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_grafana_grafana_pvc" {
  depends_on = [
    kubernetes_manifest.namespace_grafana
  ]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "name" = "grafana-pvc"
      "namespace" = "grafana"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "1Gi"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "deployment_grafana_grafana" {
  depends_on = [
    kubernetes_manifest.namespace_grafana
  ]
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "grafana"
      }
      "name" = "grafana"
      "namespace" = "grafana"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app" = "grafana"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "grafana"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "grafana/grafana:8.4.4"
              "imagePullPolicy" = "IfNotPresent"
              "livenessProbe" = {
                "failureThreshold" = 3
                "initialDelaySeconds" = 30
                "periodSeconds" = 10
                "successThreshold" = 1
                "tcpSocket" = {
                  "port" = 3000
                }
                "timeoutSeconds" = 1
              }
              "name" = "grafana"
              "ports" = [
                {
                  "containerPort" = 3000
                  "name" = "http-grafana"
                  "protocol" = "TCP"
                },
              ]
              "readinessProbe" = {
                "failureThreshold" = 3
                "httpGet" = {
                  "path" = "/robots.txt"
                  "port" = 3000
                  "scheme" = "HTTP"
                }
                "initialDelaySeconds" = 10
                "periodSeconds" = 30
                "successThreshold" = 1
                "timeoutSeconds" = 2
              }
              "resources" = {
                "requests" = {
                  "cpu" = "250m"
                  "memory" = "750Mi"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/var/lib/grafana"
                  "name" = "grafana-pv"
                },
              ]
            },
          ]
          "securityContext" = {
            "fsGroup" = 472
            "supplementalGroups" = [
              0,
            ]
          }
          "volumes" = [
            {
              "name" = "grafana-pv"
              "persistentVolumeClaim" = {
                "claimName" = "grafana-pvc"
              }
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_grafana_grafana" {
  depends_on = [
    kubernetes_manifest.namespace_grafana
  ]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "grafana"
      "namespace" = "grafana"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 3000
          "protocol" = "TCP"
          "targetPort" = "http-grafana"
        },
      ]
      "selector" = {
        "app" = "grafana"
      }
      "type" = "NodePort"
    }
  }
}

resource "kubernetes_manifest" "ingress_grafana_grafana_ingress" {
  depends_on = [
    kubernetes_manifest.namespace_grafana
  ]
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "Ingress"
    "metadata" = {
      "name" = "grafana-ingress"
      "namespace" = "grafana"
    }
    "spec" = {
      "ingressClassName" = "nginx"
      "rules" = [
        {
          "host" = "grafana.kube.home"
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "grafana"
                    "port" = {
                      "number" = 3000
                    }
                  }
                }
                "path" = "/"
                "pathType" = "Prefix"
              },
            ]
          }
        },
      ]
    }
  }
}
