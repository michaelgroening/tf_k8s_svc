resource "kubernetes_manifest" "namespace_ingress_nginx" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "ingress-nginx"
        "app.kubernetes.io/name"     = "ingress-nginx"
      }
      "name" = "ingress-nginx"
    }
  }
}

resource "kubernetes_manifest" "serviceaccount_ingress_nginx_ingress_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion"                   = "v1"
    "automountServiceAccountToken" = true
    "kind"                         = "ServiceAccount"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx"
      "namespace" = "ingress-nginx"
    }
  }
}

resource "kubernetes_manifest" "serviceaccount_ingress_nginx_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-admission"
      "namespace" = "ingress-nginx"
    }
  }
}

resource "kubernetes_manifest" "role_ingress_nginx_ingress_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "Role"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx"
      "namespace" = "ingress-nginx"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "namespaces",
        ]
        "verbs" = [
          "get",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "configmaps",
          "pods",
          "secrets",
          "endpoints",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "services",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingresses",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingresses/status",
        ]
        "verbs" = [
          "update",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingressclasses",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resourceNames" = [
          "ingress-controller-leader",
        ]
        "resources" = [
          "configmaps",
        ]
        "verbs" = [
          "get",
          "update",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "configmaps",
        ]
        "verbs" = [
          "create",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "events",
        ]
        "verbs" = [
          "create",
          "patch",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "role_ingress_nginx_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "Role"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-admission"
      "namespace" = "ingress-nginx"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "secrets",
        ]
        "verbs" = [
          "get",
          "create",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrole_ingress_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRole"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "ingress-nginx"
        "app.kubernetes.io/name"     = "ingress-nginx"
        "app.kubernetes.io/part-of"  = "ingress-nginx"
        "app.kubernetes.io/version"  = "1.2.0"
      }
      "name" = "ingress-nginx"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "configmaps",
          "endpoints",
          "nodes",
          "pods",
          "secrets",
          "namespaces",
        ]
        "verbs" = [
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "nodes",
        ]
        "verbs" = [
          "get",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "services",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingresses",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "events",
        ]
        "verbs" = [
          "create",
          "patch",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingresses/status",
        ]
        "verbs" = [
          "update",
        ]
      },
      {
        "apiGroups" = [
          "networking.k8s.io",
        ]
        "resources" = [
          "ingressclasses",
        ]
        "verbs" = [
          "get",
          "list",
          "watch",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrole_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRole"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name" = "ingress-nginx-admission"
    }
    "rules" = [
      {
        "apiGroups" = [
          "admissionregistration.k8s.io",
        ]
        "resources" = [
          "validatingwebhookconfigurations",
        ]
        "verbs" = [
          "get",
          "update",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "rolebinding_ingress_nginx_ingress_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "RoleBinding"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx"
      "namespace" = "ingress-nginx"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "Role"
      "name"     = "ingress-nginx"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "ingress-nginx"
        "namespace" = "ingress-nginx"
      },
    ]
  }
}

resource "kubernetes_manifest" "rolebinding_ingress_nginx_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "RoleBinding"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-admission"
      "namespace" = "ingress-nginx"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "Role"
      "name"     = "ingress-nginx-admission"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "ingress-nginx-admission"
        "namespace" = "ingress-nginx"
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_ingress_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "ingress-nginx"
        "app.kubernetes.io/name"     = "ingress-nginx"
        "app.kubernetes.io/part-of"  = "ingress-nginx"
        "app.kubernetes.io/version"  = "1.2.0"
      }
      "name" = "ingress-nginx"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = "ingress-nginx"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "ingress-nginx"
        "namespace" = "ingress-nginx"
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name" = "ingress-nginx-admission"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = "ingress-nginx-admission"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "ingress-nginx-admission"
        "namespace" = "ingress-nginx"
      },
    ]
  }
}

resource "kubernetes_manifest" "configmap_ingress_nginx_ingress_nginx_controller" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "allow-snippet-annotations" = "true"
      "use-forwarded-headers" = "true"
      "compute-full-forwarded-for" = "true"
      "use-proxy-protocol" = "true"
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-controller"
      "namespace" = "ingress-nginx"
    }
  }
}

resource "kubernetes_manifest" "service_ingress_nginx_ingress_nginx_controller" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-controller"
      "namespace" = "ingress-nginx"
      "annotations" = {
        "load-balancer.hetzner.cloud/name" = "kubelb"
        "load-balancer.hetzner.cloud/health-check-protocol": "http"
        "load-balancer.hetzner.cloud/health-check-http-path": "/healthz"
        "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
        "load-balancer.hetzner.cloud/protocol": "tcp"
      }
    }
    "spec" = {
      "ports" = [
        {
          "name"        = "http"
          "port"        = 80
          "protocol"    = "TCP"
          "targetPort"  = "http"
        },
      ]
      "selector" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
      }
      "type" = "LoadBalancer"
      "externalTrafficPolicy" = "Cluster"
    }
  }
}

resource "kubernetes_manifest" "service_ingress_nginx_ingress_nginx_controller_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-controller-admission"
      "namespace" = "ingress-nginx"
    }
    "spec" = {
      "ports" = [
        {
          "appProtocol" = "https"
          "name"        = "https-webhook"
          "port"        = 443
          "targetPort"  = "webhook"
        },
      ]
      "selector" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
      }
      "type" = "ClusterIP"
    }
  }
}

resource "kubernetes_manifest" "deployment_ingress_nginx_ingress_nginx_controller" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }

      "name"      = "ingress-nginx-controller"
      "namespace" = "ingress-nginx"
    }
    "spec" = {
      "revisionHistoryLimit" = 10
      "selector" = {
        "matchLabels" = {
          "app.kubernetes.io/component" = "controller"
          "app.kubernetes.io/instance"  = "ingress-nginx"
          "app.kubernetes.io/name"      = "ingress-nginx"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app.kubernetes.io/component" = "controller"
            "app.kubernetes.io/instance"  = "ingress-nginx"
            "app.kubernetes.io/name"      = "ingress-nginx"
          }
          "annotations" = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port" = "10254"
            "prometheus.io/scheme" = "http"
          }
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "/nginx-ingress-controller",
                "--enable-metrics",
                "--election-id=ingress-controller-leader",
                "--controller-class=k8s.io/ingress-nginx",
                "--ingress-class=nginx",
                "--configmap=$(POD_NAMESPACE)/ingress-nginx-controller",
                "--validating-webhook=:8443",
                "--validating-webhook-certificate=/usr/local/certificates/cert",
                "--validating-webhook-key=/usr/local/certificates/key",
              ]
              "env" = [
                {
                  "name" = "POD_NAME"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.name"
                    }
                  }
                },
                {
                  "name" = "POD_NAMESPACE"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.namespace"
                    }
                  }
                },
                {
                  "name"  = "LD_PRELOAD"
                  "value" = "/usr/local/lib/libmimalloc.so"
                },
              ]
              "image"           = "k8s.gcr.io/ingress-nginx/controller:v1.2.0@sha256:d8196e3bc1e72547c5dec66d6556c0ff92a23f6d0919b206be170bc90d5f9185"
              "imagePullPolicy" = "IfNotPresent"
              "lifecycle" = {
                "preStop" = {
                  "exec" = {
                    "command" = [
                      "/wait-shutdown",
                    ]
                  }
                }
              }
              "livenessProbe" = {
                "failureThreshold" = 5
                "httpGet" = {
                  "path"   = "/healthz"
                  "port"   = 10254
                  "scheme" = "HTTP"
                }
                "initialDelaySeconds" = 10
                "periodSeconds"       = 10
                "successThreshold"    = 1
                "timeoutSeconds"      = 1
              }
              "name" = "controller"
              "ports" = [
                {
                  "containerPort" = 80
                  "name"          = "http"
                  "protocol"      = "TCP"
                },
                {
                  "containerPort" = 443
                  "name"          = "https"
                  "protocol"      = "TCP"
                },
                {
                  "containerPort" = 8443
                  "name"          = "webhook"
                  "protocol"      = "TCP"
                },
                {
                  "containerPort" = 10254
                  "name"          = "nginx-metrics"
                  "protocol"      = "TCP"
                },
              ]
              "readinessProbe" = {
                "failureThreshold" = 3
                "httpGet" = {
                  "path"   = "/healthz"
                  "port"   = 10254
                  "scheme" = "HTTP"
                }
                "initialDelaySeconds" = 10
                "periodSeconds"       = 10
                "successThreshold"    = 1
                "timeoutSeconds"      = 1
              }
              "resources" = {
                "requests" = {
                  "cpu"    = "100m"
                  "memory" = "90Mi"
                }
              }
              "securityContext" = {
                "allowPrivilegeEscalation" = true
                "capabilities" = {
                  "add" = [
                    "NET_BIND_SERVICE",
                  ]
                  "drop" = [
                    "ALL",
                  ]
                }
                "runAsUser" = 101
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/usr/local/certificates/"
                  "name"      = "webhook-cert"
                  "readOnly"  = true
                },
              ]
            },
          ]
          "dnsPolicy" = "ClusterFirst"
          "nodeSelector" = {
            "kubernetes.io/os" = "linux"
          }
          "serviceAccountName"            = "ingress-nginx"
          "terminationGracePeriodSeconds" = 300
          "volumes" = [
            {
              "name" = "webhook-cert"
              "secret" = {
                "secretName" = "ingress-nginx-admission"
              }
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "job_ingress_nginx_ingress_nginx_admission_create" {
  computed_fields = ["spec.template.metadata.labels"]
  depends_on = [kubernetes_manifest.namespace_ingress_nginx, kubernetes_manifest.clusterrole_ingress_nginx_admission]
  manifest = {
    "apiVersion" = "batch/v1"
    "kind"       = "Job"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-admission-create"
      "namespace" = "ingress-nginx"
    }
    "spec" = {
      "template" = {
        "metadata" = {
          "labels" = {
            "app.kubernetes.io/component" = "admission-webhook"
            "app.kubernetes.io/instance"  = "ingress-nginx"
            "app.kubernetes.io/name"      = "ingress-nginx"
            "app.kubernetes.io/part-of"   = "ingress-nginx"
            "app.kubernetes.io/version"   = "1.2.0"
            "job-name"                    = "ingress-nginx-admission-create"
            // "controller-uid" = "a4c403fe-6fc1-496d-b2b5-16b4d78dc621"
          }
          "name" = "ingress-nginx-admission-create"
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "create",
                "--host=ingress-nginx-controller-admission,ingress-nginx-controller-admission.$(POD_NAMESPACE).svc",
                "--namespace=$(POD_NAMESPACE)",
                "--secret-name=ingress-nginx-admission",
              ]
              "env" = [
                {
                  "name" = "POD_NAMESPACE"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.namespace"
                    }
                  }
                },
              ]
              "image"           = "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660"
              "imagePullPolicy" = "IfNotPresent"
              "name"            = "create"
              "securityContext" = {
                "allowPrivilegeEscalation" = false
              }
            },
          ]
          "nodeSelector" = {
            "kubernetes.io/os" = "linux"
          }
          "restartPolicy" = "OnFailure"
          "securityContext" = {
            "fsGroup"      = 2000
            "runAsNonRoot" = true
            "runAsUser"    = 2000
          }
          "serviceAccountName" = "ingress-nginx-admission"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "job_ingress_nginx_ingress_nginx_admission_patch" {
  computed_fields = ["spec.template.metadata.labels"]
  depends_on = [kubernetes_manifest.namespace_ingress_nginx, kubernetes_manifest.clusterrole_ingress_nginx_admission]
  manifest = {
    "apiVersion" = "batch/v1"
    "kind"       = "Job"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name"      = "ingress-nginx-admission-patch"
      "namespace" = "ingress-nginx"
    }
    "spec" = {
      "template" = {
        "metadata" = {
          "labels" = {
            "app.kubernetes.io/component" = "admission-webhook"
            "app.kubernetes.io/instance"  = "ingress-nginx"
            "app.kubernetes.io/name"      = "ingress-nginx"
            "app.kubernetes.io/part-of"   = "ingress-nginx"
            "app.kubernetes.io/version"   = "1.2.0"
            "job-name"                    = "ingress-nginx-admission-patch"
            // "controller-uid" = "af507789-8088-45c7-afcc-e53ad168c450"
          }
          "name" = "ingress-nginx-admission-patch"
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "patch",
                "--webhook-name=ingress-nginx-admission",
                "--namespace=$(POD_NAMESPACE)",
                "--patch-mutating=false",
                "--secret-name=ingress-nginx-admission",
                "--patch-failure-policy=Fail",
              ]
              "env" = [
                {
                  "name" = "POD_NAMESPACE"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.namespace"
                    }
                  }
                },
              ]
              "image"           = "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660"
              "imagePullPolicy" = "IfNotPresent"
              "name"            = "patch"
              "securityContext" = {
                "allowPrivilegeEscalation" = false
              }
            },
          ]
          "nodeSelector" = {
            "kubernetes.io/os" = "linux"
          }
          "restartPolicy" = "OnFailure"
          "securityContext" = {
            "fsGroup"      = 2000
            "runAsNonRoot" = true
            "runAsUser"    = 2000
          }
          "serviceAccountName" = "ingress-nginx-admission"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "ingressclass_nginx" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "IngressClass"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "controller"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name" = "nginx"
    }
    "spec" = {
      "controller" = "k8s.io/ingress-nginx"
    }
  }
}

resource "kubernetes_manifest" "validatingwebhookconfiguration_ingress_nginx_admission" {
  depends_on = [kubernetes_manifest.namespace_ingress_nginx]
  manifest = {
    "apiVersion" = "admissionregistration.k8s.io/v1"
    "kind"       = "ValidatingWebhookConfiguration"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/component" = "admission-webhook"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/part-of"   = "ingress-nginx"
        "app.kubernetes.io/version"   = "1.2.0"
      }
      "name" = "ingress-nginx-admission"
    }
    "webhooks" = [
      {
        "admissionReviewVersions" = [
          "v1",
        ]
        "clientConfig" = {
          "service" = {
            "name"      = "ingress-nginx-controller-admission"
            "namespace" = "ingress-nginx"
            "path"      = "/networking/v1/ingresses"
          }
        }
        "failurePolicy" = "Fail"
        "matchPolicy"   = "Equivalent"
        "name"          = "validate.nginx.ingress.kubernetes.io"
        "rules" = [
          {
            "apiGroups" = [
              "networking.k8s.io",
            ]
            "apiVersions" = [
              "v1",
            ]
            "operations" = [
              "CREATE",
              "UPDATE",
            ]
            "resources" = [
              "ingresses",
            ]
          },
        ]
        "sideEffects" = "None"
      },
    ]
  }
}
