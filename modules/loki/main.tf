resource "kubernetes_manifest" "namespace_loki" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "loki"
    }
  }
}

resource "kubernetes_manifest" "podsecuritypolicy_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "policy/v1beta1"
    "kind" = "PodSecurityPolicy"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
    }
    "spec" = {
      "allowPrivilegeEscalation" = false
      "fsGroup" = {
        "ranges" = [
          {
            "max" = 65535
            "min" = 1
          },
        ]
        "rule" = "MustRunAs"
      }
      /* "hostIPC" = false
      "hostNetwork" = false
      "hostPID" = false
      "privileged" = false */
      "readOnlyRootFilesystem" = true
      "requiredDropCapabilities" = [
        "ALL",
      ]
      "runAsUser" = {
        "rule" = "MustRunAsNonRoot"
      }
      "seLinux" = {
        "rule" = "RunAsAny"
      }
      "supplementalGroups" = {
        "ranges" = [
          {
            "max" = 65535
            "min" = 1
          },
        ]
        "rule" = "MustRunAs"
      }
      "volumes" = [
        "configMap",
        "emptyDir",
        "persistentVolumeClaim",
        "secret",
        "projected",
        "downwardAPI",
      ]
    }
  }
}

resource "kubernetes_manifest" "serviceaccount_loki_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "automountServiceAccountToken" = true
    "kind" = "ServiceAccount"
    "metadata" = {
      "annotations" = {}
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
  }
}

resource "kubernetes_manifest" "secret_loki_simple_loki" {
  computed_fields = ["stringData","data"]
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    /* "data" = {
      "loki.yaml" = "YXV0aF9lbmFibGVkOiBmYWxzZQpjaHVua19zdG9yZV9jb25maWc6CiAgbWF4X2xvb2tfYmFja19wZXJpb2Q6IDBzCmNvbXBhY3RvcjoKICBzaGFyZWRfc3RvcmU6IGZpbGVzeXN0ZW0KICB3b3JraW5nX2RpcmVjdG9yeTogL2RhdGEvbG9raS9ib2x0ZGItc2hpcHBlci1jb21wYWN0b3IKaW5nZXN0ZXI6CiAgY2h1bmtfYmxvY2tfc2l6ZTogMjYyMTQ0CiAgY2h1bmtfaWRsZV9wZXJpb2Q6IDNtCiAgY2h1bmtfcmV0YWluX3BlcmlvZDogMW0KICBsaWZlY3ljbGVyOgogICAgcmluZzoKICAgICAgcmVwbGljYXRpb25fZmFjdG9yOiAxCiAgbWF4X3RyYW5zZmVyX3JldHJpZXM6IDAKICB3YWw6CiAgICBkaXI6IC9kYXRhL2xva2kvd2FsCmxpbWl0c19jb25maWc6CiAgZW5mb3JjZV9tZXRyaWNfbmFtZTogZmFsc2UKICBtYXhfZW50cmllc19saW1pdF9wZXJfcXVlcnk6IDUwMDAKICByZWplY3Rfb2xkX3NhbXBsZXM6IHRydWUKICByZWplY3Rfb2xkX3NhbXBsZXNfbWF4X2FnZTogMTY4aAptZW1iZXJsaXN0OgogIGpvaW5fbWVtYmVyczoKICAtICdyZWxlYXNlLW5hbWUtbG9raS1tZW1iZXJsaXN0JwpzY2hlbWFfY29uZmlnOgogIGNvbmZpZ3M6CiAgLSBmcm9tOiAiMjAyMC0xMC0yNCIKICAgIGluZGV4OgogICAgICBwZXJpb2Q6IDI0aAogICAgICBwcmVmaXg6IGluZGV4XwogICAgb2JqZWN0X3N0b3JlOiBmaWxlc3lzdGVtCiAgICBzY2hlbWE6IHYxMQogICAgc3RvcmU6IGJvbHRkYi1zaGlwcGVyCnNlcnZlcjoKICBncnBjX2xpc3Rlbl9wb3J0OiA5MDk1CiAgaHR0cF9saXN0ZW5fcG9ydDogMzEwMApzdG9yYWdlX2NvbmZpZzoKICBib2x0ZGJfc2hpcHBlcjoKICAgIGFjdGl2ZV9pbmRleF9kaXJlY3Rvcnk6IC9kYXRhL2xva2kvYm9sdGRiLXNoaXBwZXItYWN0aXZlCiAgICBjYWNoZV9sb2NhdGlvbjogL2RhdGEvbG9raS9ib2x0ZGItc2hpcHBlci1jYWNoZQogICAgY2FjaGVfdHRsOiAyNGgKICAgIHNoYXJlZF9zdG9yZTogZmlsZXN5c3RlbQogIGZpbGVzeXN0ZW06CiAgICBkaXJlY3Rvcnk6IC9kYXRhL2xva2kvY2h1bmtzCnRhYmxlX21hbmFnZXI6CiAgcmV0ZW50aW9uX2RlbGV0ZXNfZW5hYmxlZDogZmFsc2UKICByZXRlbnRpb25fcGVyaW9kOiAwcw=="
    } */
    "stringData" = {
      "loki.yaml" = <<-EOT
      auth_enabled: false
      chunk_store_config:
        max_look_back_period: 0s
      compactor:
        shared_store: filesystem
        working_directory: /data/loki/boltdb-shipper-compactor
      ingester:
        chunk_block_size: 262144
        chunk_idle_period: 3m
        chunk_retain_period: 1m
        lifecycler:
          ring:
            replication_factor: 1
        max_transfer_retries: 0
        wal:
          dir: /data/loki/wal
      limits_config:
        enforce_metric_name: false
        max_entries_limit_per_query: 5000
        reject_old_samples: true
        reject_old_samples_max_age: 168h
      memberlist:
        join_members:
        - 'simple-loki-memberlist'
      schema_config:
        configs:
        - from: "2020-10-24"
          index:
            period: 24h
            prefix: index_
          object_store: filesystem
          schema: v11
          store: boltdb-shipper
      server:
        grpc_listen_port: 9095
        http_listen_port: 3100
      storage_config:
        boltdb_shipper:
          active_index_directory: /data/loki/boltdb-shipper-active
          cache_location: /data/loki/boltdb-shipper-cache
          cache_ttl: 24h
          shared_store: filesystem
        filesystem:
          directory: /data/loki/chunks
      table_manager:
        retention_deletes_enabled: false
        retention_period: 0s
      EOT
    }
    "kind" = "Secret"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
  }
}

resource "kubernetes_manifest" "role_loki_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "Role"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
    "rules" = [
      {
        "apiGroups" = [
          "extensions",
        ]
        "resourceNames" = [
          "simple-loki",
        ]
        "resources" = [
          "podsecuritypolicies",
        ]
        "verbs" = [
          "use",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "rolebinding_loki_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "RoleBinding"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "Role"
      "name" = "simple-loki"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "simple-loki"
      },
    ]
  }
}

resource "kubernetes_manifest" "service_loki_simple_loki_headless" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
        "variant" = "headless"
      }
      "name" = "simple-loki-headless"
      "namespace" = "loki"
    }
    "spec" = {
      "clusterIP" = "None"
      "ports" = [
        {
          "name" = "http-metrics"
          "port" = 3100
          "protocol" = "TCP"
          "targetPort" = "http-metrics"
        },
      ]
      "selector" = {
        "app" = "loki"
        "release" = "simple"
      }
    }
  }
}

resource "kubernetes_manifest" "service_loki_simple_loki_memberlist" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki-memberlist"
      "namespace" = "loki"
    }
    "spec" = {
      "clusterIP" = "None"
      "ports" = [
        {
          "name" = "http"
          "port" = 7946
          "protocol" = "TCP"
          "targetPort" = "memberlist-port"
        },
      ]
      "publishNotReadyAddresses" = true
      "selector" = {
        "app" = "loki"
        "release" = "simple"
      }
      "type" = "ClusterIP"
    }
  }
}

resource "kubernetes_manifest" "service_loki_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "annotations" = {}
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
    "spec" = {
      "ports" = [
        {
          "name" = "http-metrics"
          "port" = 3100
          "protocol" = "TCP"
          "targetPort" = "http-metrics"
        },
      ]
      "selector" = {
        "app" = "loki"
        "release" = "simple"
      }
      "type" = "ClusterIP"
    }
  }
}

resource "kubernetes_manifest" "statefulset_loki_simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "StatefulSet"
    "metadata" = {
      "annotations" = {}
      "labels" = {
        "app" = "loki"
        "chart" = "loki-2.12.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
    "spec" = {
      "podManagementPolicy" = "OrderedReady"
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "loki"
          "release" = "simple"
        }
      }
      "serviceName" = "simple-loki-headless"
      "template" = {
        "metadata" = {
          "annotations" = {
            "checksum/config" = "875b10418b91798afca9405a17e932560628ef4ea178449bc1f263201d9b9d6c"
            "prometheus.io/port" = "http-metrics"
            "prometheus.io/scrape" = "true"
          }
          "labels" = {
            "app" = "loki"
            "name" = "simple-loki"
            "release" = "simple"
          }
        }
        "spec" = {
          "affinity" = {}
          "containers" = [
            {
              "args" = [
                "-config.file=/etc/loki/loki.yaml",
              ]
              "env" = null
              "image" = "grafana/loki:2.5.0"
              "imagePullPolicy" = "IfNotPresent"
              "livenessProbe" = {
                "httpGet" = {
                  "path" = "/ready"
                  "port" = "http-metrics"
                }
                "initialDelaySeconds" = 45
              }
              "name" = "loki"
              "ports" = [
                {
                  "containerPort" = 3100
                  "name" = "http-metrics"
                  "protocol" = "TCP"
                },
                {
                  "containerPort" = 9095
                  "name" = "grpc"
                  "protocol" = "TCP"
                },
                {
                  "containerPort" = 7946
                  "name" = "memberlist-port"
                  "protocol" = "TCP"
                },
              ]
              "readinessProbe" = {
                "httpGet" = {
                  "path" = "/ready"
                  "port" = "http-metrics"
                }
                "initialDelaySeconds" = 45
              }
              "resources" = {}
              "securityContext" = {
                "readOnlyRootFilesystem" = true
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/tmp"
                  "name" = "tmp"
                },
                {
                  "mountPath" = "/etc/loki"
                  "name" = "config"
                },
                {
                  "mountPath" = "/data"
                  "name" = "storage"
                  "subPath" = null
                },
              ]
            },
          ]
          /* "initContainers" = [] */
          /* "nodeSelector" = {} */
          "securityContext" = {
            "fsGroup" = 10001
            "runAsGroup" = 10001
            "runAsNonRoot" = true
            "runAsUser" = 10001
          }
          "serviceAccountName" = "simple-loki"
          "terminationGracePeriodSeconds" = 4800
          /* "tolerations" = [] */
          "volumes" = [
            {
              "emptyDir" = {}
              "name" = "tmp"
            },
            {
              "name" = "config"
              "secret" = {
                "secretName" = "simple-loki"
              }
            },
            {
              "emptyDir" = {}
              "name" = "storage"
            },
          ]
        }
      }
      "updateStrategy" = {
        "type" = "RollingUpdate"
      }
    }
  }
}

resource "kubernetes_manifest" "serviceaccount_loki_simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "simple"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "promtail"
        "app.kubernetes.io/version" = "2.5.0"
        "helm.sh/chart" = "promtail-5.1.0"
      }
      "name" = "simple-promtail"
      "namespace" = "loki"
    }
  }
}

resource "kubernetes_manifest" "secret_loki_simple_promtail" {
  computed_fields = ["stringData","data"]
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Secret"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "simple"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "promtail"
        "app.kubernetes.io/version" = "2.5.0"
        "helm.sh/chart" = "promtail-5.1.0"
      }
      "name" = "simple-promtail"
      "namespace" = "loki"
    }
    "stringData" = {
      "promtail.yaml" = <<-EOT
      server:
        log_level: info
        http_listen_port: 3101

      clients:
        - url: http://simple-loki.loki.svc.cluster.local:3100/loki/api/v1/push

      positions:
        filename: /run/promtail/positions.yaml

      scrape_configs:
        # See also https://github.com/grafana/loki/blob/master/production/ksonnet/promtail/scrape_config.libsonnet for reference
        - job_name: kubernetes-pods
          pipeline_stages:
            - cri: {}
          kubernetes_sd_configs:
            - role: pod
          relabel_configs:
            - source_labels:
                - __meta_kubernetes_pod_controller_name
              regex: ([0-9a-z-.]+?)(-[0-9a-f]{8,10})?
              action: replace
              target_label: __tmp_controller_name
            - source_labels:
                - __meta_kubernetes_pod_label_app_kubernetes_io_name
                - __meta_kubernetes_pod_label_app
                - __tmp_controller_name
                - __meta_kubernetes_pod_name
              regex: ^;*([^;]+)(;.*)?$
              action: replace
              target_label: app
            - source_labels:
                - __meta_kubernetes_pod_label_app_kubernetes_io_instance
                - __meta_kubernetes_pod_label_release
              regex: ^;*([^;]+)(;.*)?$
              action: replace
              target_label: instance
            - source_labels:
                - __meta_kubernetes_pod_label_app_kubernetes_io_component
                - __meta_kubernetes_pod_label_component
              regex: ^;*([^;]+)(;.*)?$
              action: replace
              target_label: component
            - action: replace
              source_labels:
              - __meta_kubernetes_pod_node_name
              target_label: node_name
            - action: replace
              source_labels:
              - __meta_kubernetes_namespace
              target_label: namespace
            - action: replace
              replacement: $1
              separator: /
              source_labels:
              - namespace
              - app
              target_label: job
            - action: replace
              source_labels:
              - __meta_kubernetes_pod_name
              target_label: pod
            - action: replace
              source_labels:
              - __meta_kubernetes_pod_container_name
              target_label: container
            - action: replace
              replacement: /var/log/pods/*$1/*.log
              separator: /
              source_labels:
              - __meta_kubernetes_pod_uid
              - __meta_kubernetes_pod_container_name
              target_label: __path__
            - action: replace
              regex: true/(.*)
              replacement: /var/log/pods/*$1/*.log
              separator: /
              source_labels:
              - __meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash
              - __meta_kubernetes_pod_annotation_kubernetes_io_config_hash
              - __meta_kubernetes_pod_container_name
              target_label: __path__
      EOT
    }
  }
}

resource "kubernetes_manifest" "clusterrole_simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRole"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "simple"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "promtail"
        "app.kubernetes.io/version" = "2.5.0"
        "helm.sh/chart" = "promtail-5.1.0"
      }
      "name" = "simple-promtail"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "nodes",
          "nodes/proxy",
          "services",
          "endpoints",
          "pods",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRoleBinding"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "simple"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "promtail"
        "app.kubernetes.io/version" = "2.5.0"
        "helm.sh/chart" = "promtail-5.1.0"
      }
      "name" = "simple-promtail"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "ClusterRole"
      "name" = "simple-promtail"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "simple-promtail"
        "namespace" = "loki"
      },
    ]
  }
}

resource "kubernetes_manifest" "daemonset_loki_simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "DaemonSet"
    "metadata" = {
      "labels" = {
        "app.kubernetes.io/instance" = "simple"
        "app.kubernetes.io/managed-by" = "Helm"
        "app.kubernetes.io/name" = "promtail"
        "app.kubernetes.io/version" = "2.5.0"
        "helm.sh/chart" = "promtail-5.1.0"
      }
      "name" = "simple-promtail"
      "namespace" = "loki"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app.kubernetes.io/instance" = "simple"
          "app.kubernetes.io/name" = "promtail"
        }
      }
      "template" = {
        "metadata" = {
          "annotations" = {
            "checksum/config" = "e2dacf332b457c568e5ba194e9bbb56fbd0607f5fd0b1f9eb7ed09927344da53"
            "prometheus.io/port" = "http-metrics"
            "prometheus.io/scrape" = "true"
          }
          "labels" = {
            "app.kubernetes.io/instance" = "simple"
            "app.kubernetes.io/name" = "promtail"
          }
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "-config.file=/etc/promtail/promtail.yaml",
              ]
              "env" = [
                {
                  "name" = "HOSTNAME"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "spec.nodeName"
                    }
                  }
                },
              ]
              "image" = "docker.io/grafana/promtail:2.5.0"
              "imagePullPolicy" = "IfNotPresent"
              "name" = "promtail"
              "ports" = [
                {
                  "containerPort" = 3101
                  "name" = "http-metrics"
                  "protocol" = "TCP"
                },
              ]
              "readinessProbe" = {
                "failureThreshold" = 5
                "httpGet" = {
                  "path" = "/ready"
                  "port" = "http-metrics"
                }
                "initialDelaySeconds" = 10
                "periodSeconds" = 10
                "successThreshold" = 1
                "timeoutSeconds" = 1
              }
              "securityContext" = {
                "allowPrivilegeEscalation" = false
                "capabilities" = {
                  "drop" = [
                    "ALL",
                  ]
                }
                "readOnlyRootFilesystem" = true
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/etc/promtail"
                  "name" = "config"
                },
                {
                  "mountPath" = "/run/promtail"
                  "name" = "run"
                },
                {
                  "mountPath" = "/var/lib/docker/containers"
                  "name" = "containers"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/var/log/pods"
                  "name" = "pods"
                  "readOnly" = true
                },
              ]
            },
          ]
          "securityContext" = {
            "runAsGroup" = 0
            "runAsUser" = 0
          }
          "serviceAccountName" = "simple-promtail"
          "tolerations" = [
            {
              "effect" = "NoSchedule"
              "key" = "node-role.kubernetes.io/master"
              "operator" = "Exists"
            },
            {
              "effect" = "NoSchedule"
              "key" = "node-role.kubernetes.io/control-plane"
              "operator" = "Exists"
            },
          ]
          "volumes" = [
            {
              "name" = "config"
              "secret" = {
                "secretName" = "simple-promtail"
              }
            },
            {
              "hostPath" = {
                "path" = "/run/promtail"
              }
              "name" = "run"
            },
            {
              "hostPath" = {
                "path" = "/var/lib/docker/containers"
              }
              "name" = "containers"
            },
            {
              "hostPath" = {
                "path" = "/var/log/pods"
              }
              "name" = "pods"
            },
          ]
        }
      }
      "updateStrategy" = {}
    }
  }
}
