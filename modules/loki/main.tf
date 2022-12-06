resource "kubernetes_manifest" "namespace_loki" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "loki"
    }
  }
}

# resource "kubernetes_service_account" "simple_loki" {
#   depends_on = [kubernetes_manifest.namespace_loki]
#   metadata {
#     name      = "simple-loki"
#     namespace = "loki"
#     labels = {
#       app = "loki"
#       chart = "loki-2.16.0"
#       heritage = "Helm"
#       release = "simple-loki"
#     }
#   }
#   automount_service_account_token = true
# }


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
        "chart" = "loki-2.16.0"
        "heritage" = "Helm"
        "release" = "simple"
      }
      "name" = "simple-loki"
      "namespace" = "loki"
    }
  }
}

resource "kubernetes_secret" "simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  data = {
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
}

resource "kubernetes_role" "simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  rule {
    verbs          = ["use"]
    api_groups     = ["extensions"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["simple-loki"]
  }
}

resource "kubernetes_role_binding" "simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  subject {
    kind = "ServiceAccount"
    name = "simple-loki"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "simple-loki"
  }
}

resource "kubernetes_service" "simple_loki_headless" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki-headless"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
      variant = "headless"
    }
    annotations = {
      "prometheus.io/port" = "10254"
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name        = "http-metrics"
      protocol    = "TCP"
      port        = 3100
      target_port = "http-metrics"
    }
    selector = {
      app = "loki"
      release = "simple-loki"
    }
    cluster_ip = "None"
  }
}

resource "kubernetes_service" "simple_loki_memberlist" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki-memberlist"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 7946
      target_port = "memberlist-port"
    }
    selector = {
      app = "loki"
      release = "simple-loki"
    }
    cluster_ip                  = "None"
    type                        = "ClusterIP"
    publish_not_ready_addresses = true
  }
}


resource "kubernetes_service" "simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  spec {
    port {
      name        = "http-metrics"
      protocol    = "TCP"
      port        = 3100
      target_port = "http-metrics"
    }
    selector = {
      app = "loki"
      release = "simple-loki"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_stateful_set" "simple_loki" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-loki"
    namespace = "loki"
    labels = {
      app = "loki"
      chart = "loki-2.16.0"
      heritage = "Helm"
      release = "simple-loki"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "loki"
        release = "simple-loki"
      }
    }
    template {
      metadata {
        labels = {
          app = "loki"
          name = "simple-loki"
          release = "simple-loki"
        }
        annotations = {
          "checksum/config" = "e6887662aba2935d01a5766684e5341d5f01ae64de47edcd255f93a2cb2bf956"
          "prometheus.io/port" = "http-metrics"
          "prometheus.io/scrape" = "true"
        }
      }
      spec {
        volume {
          name      = "tmp"
          empty_dir {}
        }
        volume {
          name = "config"
          secret {
            secret_name = "simple-loki"
          }
        }
        volume {
          name      = "storage"
          empty_dir {}
        }
        container {
          name  = "loki"
          image = "grafana/loki:2.6.1"
          args  = ["-config.file=/etc/loki/loki.yaml"]
          port {
            name           = "http-metrics"
            container_port = 3100
            protocol       = "TCP"
          }
          port {
            name           = "grpc"
            container_port = 9095
            protocol       = "TCP"
          }
          port {
            name           = "memberlist-port"
            container_port = 7946
            protocol       = "TCP"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/loki"
          }
          volume_mount {
            name       = "storage"
            mount_path = "/data"
          }
          liveness_probe {
            http_get {
              path = "/ready"
              port = "http-metrics"
            }
            initial_delay_seconds = 45
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "http-metrics"
            }
            initial_delay_seconds = 45
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            read_only_root_filesystem = true
          }
        }
        termination_grace_period_seconds = 4800
        service_account_name             = "simple-loki"
        security_context {
          run_as_user     = 10001
          run_as_group    = 10001
          run_as_non_root = true
          fs_group        = 10001
        }
      }
    }
    service_name          = "simple-loki-headless"
    pod_management_policy = "OrderedReady"
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

# resource "kubernetes_service_account" "simple_promtail" {
#   depends_on = [kubernetes_manifest.namespace_loki]
#   metadata {
#     name      = "simple-promtail"
#     namespace = "loki"
#     labels = {
#       "app.kubernetes.io/instance" = "simple-promtail"
#       "app.kubernetes.io/managed-by" = "Helm"
#       "app.kubernetes.io/name" = "promtail"
#       "app.kubernetes.io/version" = "2.6.1"
#       "helm.sh/chart" = "promtail-6.6.2"
#     }
#   }
# }

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

resource "kubernetes_secret" "simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-promtail"
    namespace = "loki"
    labels = {
      "app.kubernetes.io/instance" = "simple-promtail"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name" = "promtail"
      "app.kubernetes.io/version" = "2.6.1"
      "helm.sh/chart" = "promtail-6.6.2"
    }
  }
  data = {
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

resource "kubernetes_cluster_role" "simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name = "simple-promtail"
    labels = {
      "app.kubernetes.io/instance" = "simple-promtail"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name" = "promtail"
      "app.kubernetes.io/version" = "2.6.1"
      "helm.sh/chart" = "promtail-6.6.2"
    }
  }
  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  }
}

resource "kubernetes_cluster_role_binding" "simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name = "simple-promtail"
    labels = {
      "app.kubernetes.io/instance" = "simple-promtail"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name" = "promtail"
      "app.kubernetes.io/version" = "2.6.1"
      "helm.sh/chart" = "promtail-6.6.2"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "simple-promtail"
    namespace = "loki"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "simple-promtail"
  }
}


resource "kubernetes_daemonset" "simple_promtail" {
  depends_on = [kubernetes_manifest.namespace_loki]
  metadata {
    name      = "simple-promtail"
    namespace = "loki"
    labels = {
      "app.kubernetes.io/instance" = "simple-promtail"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name" = "promtail"
      "app.kubernetes.io/version" = "2.6.1"
      "helm.sh/chart" = "promtail-6.6.2"
    }
  }
  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/instance" = "simple-promtail"
        "app.kubernetes.io/name" = "promtail"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/instance" = "simple-promtail"
          "app.kubernetes.io/name" = "promtail"
        }
        annotations = {
          "checksum/config" = "44e07f0d41f62837de707e485e8658f49d1602a32cd828299e129989e9e4287c"
        }
      }
      spec {
        volume {
          name = "config"
          secret {
            secret_name = "simple-promtail"
          }
        }
        volume {
          name = "run"
          host_path {
            path = "/run/promtail"
          }
        }
        volume {
          name = "containers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
        volume {
          name = "pods"
          host_path {
            path = "/var/log/pods"
          }
        }
        container {
          name  = "promtail"
          image = "docker.io/grafana/promtail:2.6.1"
          args  = ["-config.file=/etc/promtail/promtail.yaml"]
          port {
            name           = "http-metrics"
            container_port = 3101
            protocol       = "TCP"
          }
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/promtail"
          }
          volume_mount {
            name       = "run"
            mount_path = "/run/promtail"
          }
          volume_mount {
            name       = "containers"
            read_only  = true
            mount_path = "/var/lib/docker/containers"
          }
          volume_mount {
            name       = "pods"
            read_only  = true
            mount_path = "/var/log/pods"
          }
          readiness_probe {
            http_get {
              path = "/ready"
              port = "http-metrics"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 5
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
          }
        }
        service_account_name = "simple-promtail"
        security_context {
          run_as_user = 0
        }
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        enable_service_links = true
      }
    }
  }
}
