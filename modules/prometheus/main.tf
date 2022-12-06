resource "kubernetes_namespace" "prometheus_metrics" {
  metadata {
    name = "prometheus-metrics"
  }
}
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = "prometheus-metrics"
  }
  data = {
    "prometheus.yaml" = <<-EOT
      # Global config
      global:
        scrape_interval: 15s


      # Scrape configs for running Prometheus on a Kubernetes cluster.
      # This uses separate scrape configs for cluster components (i.e. API server, node)
      # and services to allow each to use different authentication configs.
      #
      # Kubernetes labels will be added as Prometheus labels on metrics via the
      # `labelmap` relabeling action.
      scrape_configs:

      # Scrape config for API servers.
      #
      # Kubernetes exposes API servers as endpoints to the default/kubernetes
      # service so this uses `endpoints` role and uses relabelling to only keep
      # the endpoints associated with the default/kubernetes service using the
      # default named port `https`. This works for single API server deployments as
      # well as HA API server deployments.
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints

        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # Using endpoints to discover kube-apiserver targets finds the pod IP
          # (host IP since apiserver uses host network) which is not used in
          # the server certificate.
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        # Keep only the default/kubernetes service endpoints for the https port. This
        # will add targets for each API server which Kubernetes adds an endpoint to
        # the default/kubernetes service.
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
        - replacement: apiserver
          action: replace
          target_label: job

      # Scrape config for node (i.e. kubelet) /metrics (e.g. 'kubelet_'). Explore
      # metrics from a node by scraping kubelet (127.0.0.1:10250/metrics).
      - job_name: 'kubelet'
        kubernetes_sd_configs:
        - role: node

        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # Kubelet certs don't have any fixed IP SANs
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - replacement: 'prometheus-metrics'
          target_label: kubernetes_namespace

        metric_relabel_configs:
        - source_labels:
            - namespace
          action: replace
          regex: (.+)
          target_label: kubernetes_namespace

      # Scrape config for Kubelet cAdvisor. Explore metrics from a node by
      # scraping kubelet (127.0.0.1:10250/metrics/cadvisor).
      - job_name: 'kubernetes-cadvisor'
        kubernetes_sd_configs:
        - role: node

        scheme: https
        metrics_path: /metrics/cadvisor
        tls_config:
          # Kubelet certs don't have any fixed IP SANs
          insecure_skip_verify: true
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        metric_relabel_configs:
        - source_labels:
            - namespace
          action: replace
          target_label: kubernetes_namespace
        - source_labels:
          - pod
          regex: (.*)
          replacement: $1
          action: replace
          target_label: pod_name
        - source_labels:
          - container
          regex: (.*)
          replacement: $1
          action: replace
          target_label: container_name

      # Scrap etcd metrics from masters via etcd-scraper-proxy
      - job_name: 'etcd'
        kubernetes_sd_configs:
        - role: pod
        scheme: http
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace]
            action: keep
            regex: 'kube-system'
          - source_labels: [__meta_kubernetes_pod_label_component]
            action: keep
            regex: 'etcd-scraper-proxy'
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)

      # Scrape config for service endpoints.
      #
      # The relabeling allows the actual service scrape endpoint to be configured
      # via the following annotations:
      #
      # * `prometheus.io/scrape`: Only scrape services that have a value of `true`
      # * `prometheus.io/scheme`: If the metrics endpoint is secured then you will need
      # to set this to `https` & most likely set the `tls_config` of the scrape config.
      # * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
      # * `prometheus.io/port`: If the metrics are exposed on a different port to the
      # service then set this appropriately.
      - job_name: 'kubernetes-service-endpoints'

        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
              - prometheus-metrics

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
          action: replace
          target_label: __scheme__
          regex: (https?)
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
          action: replace
          target_label: __address__
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels: [__meta_kubernetes_service_name]
          action: replace
          target_label: job
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_node_name
          target_label: kubernetes_node
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        metric_relabel_configs:
        - source_labels:
            - namespace
          action: replace
          regex: (.+)
          target_label: kubernetes_namespace

      # Example scrape config for probing services via the Blackbox Exporter.
      #
      # The relabeling allows the actual service scrape endpoint to be configured
      # via the following annotations:
      #
      # * `prometheus.io/probe`: Only probe services that have a value of `true`
      - job_name: 'kubernetes-services'
        metrics_path: /metrics
        params:
          module: [http_2xx]

        kubernetes_sd_configs:
        - role: service
          namespaces:
            names:
              - prometheus-metrics
              - ingress-nginx
              - loki

        relabel_configs:
        - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
          action: keep
          regex: true

      # Example scrape config for pods
      #
      # The relabeling allows the actual pod scrape endpoint to be configured via the
      # following annotations:
      #
      # * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
      # * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
      # * `prometheus.io/port`: Scrape the pod on the indicated port instead of the
      # pod's declared ports (default is a port-free target if none are declared).
      - job_name: 'kubernetes-pods'

        kubernetes_sd_configs:
        - role: pod
          namespaces:
            names:
              - prometheus-metrics
              - ingress-nginx
              - loki

        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: kubernetes_pod_name
        metric_relabel_configs:
        - source_labels:
            - namespace
          action: replace
          regex: (.+)
          target_label: kubernetes_namespace

      # Rule files
      rule_files:
        - "/etc/prometheus/rules/*.rules"
        - "/etc/prometheus/rules/*.yaml"
        - "/etc/prometheus/rules/*.yml"
      EOT
  }
}
resource "kubernetes_config_map" "prometheus_rules" {
  metadata {
    name      = "prometheus-rules"
    namespace = "prometheus-metrics"
  }
  data = {
      "alertmanager.rules.yaml" = <<-EOT
      groups:
      - name: alertmanager.rules
        rules:
        - alert: AlertmanagerConfigInconsistent
          expr: count_values("config_hash", alertmanager_config_hash) BY (service) / ON(service)
            GROUP_LEFT() label_replace(prometheus_operator_alertmanager_spec_replicas, "service",
            "alertmanager-$1", "alertmanager", "(.*)") != 1
          for: 5m
          labels:
            severity: critical
          annotations:
            description: The configuration of the instances of the Alertmanager cluster
              `{{$labels.service}}` are out of sync.
        - alert: AlertmanagerDownOrMissing
          expr: label_replace(prometheus_operator_alertmanager_spec_replicas, "job", "alertmanager-$1",
            "alertmanager", "(.*)") / ON(job) GROUP_RIGHT() sum(up) BY (job) != 1
          for: 5m
          labels:
            severity: warning
          annotations:
            description: An unexpected number of Alertmanagers are scraped or Alertmanagers
              disappeared from discovery.
        - alert: AlertmanagerFailedReload
          expr: alertmanager_config_last_reload_successful == 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Reloading Alertmanager's configuration has failed for {{ $labels.namespace
              }}/{{ $labels.pod}}.

      EOT
      "etcd3.rules.yaml" = <<-EOT
      groups:
      - name: ./etcd3.rules
        rules:
        - alert: InsufficientMembers
          expr: count(up{job="etcd"} == 0) > (count(up{job="etcd"}) / 2 - 1)
          for: 3m
          labels:
            severity: critical
          annotations:
            description: If one more etcd member goes down the cluster will be unavailable
            summary: etcd cluster insufficient members
        - alert: NoLeader
          expr: etcd_server_has_leader{job="etcd"} == 0
          for: 1m
          labels:
            severity: critical
          annotations:
            description: etcd member {{ $labels.instance }} has no leader
            summary: etcd member has no leader
        - alert: HighNumberOfLeaderChanges
          expr: increase(etcd_server_leader_changes_seen_total{job="etcd"}[1h]) > 3
          labels:
            severity: warning
          annotations:
            description: etcd instance {{ $labels.instance }} has seen {{ $value }} leader
              changes within the last hour
            summary: a high number of leader changes within the etcd cluster are happening
        - alert: GRPCRequestsSlow
          expr: histogram_quantile(0.99, sum(rate(grpc_server_handling_seconds_bucket{job="etcd",grpc_type="unary"}[5m])) by (grpc_service, grpc_method, le))
            > 0.15
          for: 10m
          labels:
            severity: critical
          annotations:
            description: on etcd instance {{ $labels.instance }} gRPC requests to {{ $labels.grpc_method
              }} are slow
            summary: slow gRPC requests
        - alert: HighNumberOfFailedHTTPRequests
          expr: sum(rate(etcd_http_failed_total{job="etcd"}[5m])) BY (method) / sum(rate(etcd_http_received_total{job="etcd"}[5m]))
            BY (method) > 0.01
          for: 10m
          labels:
            severity: warning
          annotations:
            description: '{{ $value }}% of requests for {{ $labels.method }} failed on etcd
              instance {{ $labels.instance }}'
            summary: a high number of HTTP requests are failing
        - alert: HighNumberOfFailedHTTPRequests
          expr: sum(rate(etcd_http_failed_total{job="etcd"}[5m])) BY (method) / sum(rate(etcd_http_received_total{job="etcd"}[5m]))
            BY (method) > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            description: '{{ $value }}% of requests for {{ $labels.method }} failed on etcd
              instance {{ $labels.instance }}'
            summary: a high number of HTTP requests are failing
        - alert: HTTPRequestsSlow
          expr: histogram_quantile(0.99, rate(etcd_http_successful_duration_seconds_bucket[5m]))
            > 0.15
          for: 10m
          labels:
            severity: warning
          annotations:
            description: on etcd instance {{ $labels.instance }} HTTP requests to {{ $labels.method
              }} are slow
            summary: slow HTTP requests
        - alert: EtcdMemberCommunicationSlow
          expr: histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[5m]))
            > 0.15
          for: 10m
          labels:
            severity: warning
          annotations:
            description: etcd instance {{ $labels.instance }} member communication with
              {{ $labels.To }} is slow
            summary: etcd member communication is slow
        - alert: HighNumberOfFailedProposals
          expr: increase(etcd_server_proposals_failed_total{job="etcd"}[1h]) > 5
          labels:
            severity: warning
          annotations:
            description: etcd instance {{ $labels.instance }} has seen {{ $value }} proposal
              failures within the last hour
            summary: a high number of proposals within the etcd cluster are failing
        - alert: HighFsyncDurations
          expr: histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))
            > 0.5
          for: 10m
          labels:
            severity: warning
          annotations:
            description: etcd instance {{ $labels.instance }} fync durations are high
            summary: high fsync durations
        - alert: HighCommitDurations
          expr: histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))
            > 0.25
          for: 10m
          labels:
            severity: warning
          annotations:
            description: etcd instance {{ $labels.instance }} commit durations are high
            summary: high commit durations

      EOT
      "general.rules.yaml" = <<-EOT
      groups:
      - name: general.rules
        rules:
        - alert: TargetDown
          expr: 100 * (count(up == 0) BY (job) / count(up) BY (job)) > 10
          for: 10m
          labels:
            severity: warning
          annotations:
            description: '{{ $value }}% of {{ $labels.job }} targets are down.'
            summary: Targets are down
        - record: fd_utilization
          expr: process_open_fds / process_max_fds
        - alert: FdExhaustionClose
          expr: predict_linear(fd_utilization[1h], 3600 * 4) > 1
          for: 10m
          labels:
            severity: warning
          annotations:
            description: '{{ $labels.job }}: {{ $labels.namespace }}/{{ $labels.pod }} instance
              will exhaust in file/socket descriptors within the next 4 hours'
            summary: file descriptors soon exhausted
        - alert: FdExhaustionClose
          expr: predict_linear(fd_utilization[10m], 3600) > 1
          for: 10m
          labels:
            severity: critical
          annotations:
            description: '{{ $labels.job }}: {{ $labels.namespace }}/{{ $labels.pod }} instance
              will exhaust in file/socket descriptors within the next hour'
            summary: file descriptors soon exhausted

      EOT
      "kube-state-metrics.rules.yaml" = <<-EOT
      groups:
      - name: kube-state-metrics.rules
        rules:
        - alert: DeploymentGenerationMismatch
          expr: kube_deployment_status_observed_generation != kube_deployment_metadata_generation
          for: 15m
          labels:
            severity: warning
          annotations:
            description: Observed deployment generation does not match expected one for
              deployment {{$labels.namespaces}}/{{$labels.deployment}}
            summary: Deployment is outdated
        - alert: DeploymentReplicasNotUpdated
          expr: ((kube_deployment_status_replicas_updated != kube_deployment_spec_replicas)
            or (kube_deployment_status_replicas_available != kube_deployment_spec_replicas))
            unless (kube_deployment_spec_paused == 1)
          for: 15m
          labels:
            severity: warning
          annotations:
            description: Replicas are not updated and available for deployment {{$labels.namespaces}}/{{$labels.deployment}}
            summary: Deployment replicas are outdated
        - alert: DaemonSetRolloutStuck
          expr: kube_daemonset_status_number_ready / kube_daemonset_status_desired_number_scheduled
            * 100 < 100
          for: 15m
          labels:
            severity: warning
          annotations:
            description: Only {{$value}}% of desired pods scheduled and ready for daemon
              set {{$labels.namespaces}}/{{$labels.daemonset}}
            summary: DaemonSet is missing pods
        - alert: K8SDaemonSetsNotScheduled
          expr: kube_daemonset_status_desired_number_scheduled - kube_daemonset_status_current_number_scheduled
            > 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: A number of daemonsets are not scheduled.
            summary: Daemonsets are not scheduled correctly
        - alert: DaemonSetsMissScheduled
          expr: kube_daemonset_status_number_misscheduled > 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: A number of daemonsets are running where they are not supposed
              to run.
            summary: Daemonsets are not scheduled correctly
        - alert: PodFrequentlyRestarting
          expr: increase(kube_pod_container_status_restarts_total[1h]) > 5
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Pod {{$labels.namespaces}}/{{$labels.pod}} restarted {{$value}}
              times within the last hour
            summary: Pod is restarting frequently

      EOT
      "kubelet.rules.yaml" = <<-EOT
      groups:
      - name: kubelet.rules
        rules:
        - alert: K8SNodeNotReady
          expr: kube_node_status_condition{condition="Ready",status="true"} == 0
          for: 1h
          labels:
            severity: warning
          annotations:
            description: The Kubelet on {{ $labels.node }} has not checked in with the API,
              or has set itself to NotReady, for more than an hour
            summary: Node status is NotReady
        - alert: K8SManyNodesNotReady
          expr: count(kube_node_status_condition{condition="Ready",status="true"} == 0)
            > 1 and (count(kube_node_status_condition{condition="Ready",status="true"} ==
            0) / count(kube_node_status_condition{condition="Ready",status="true"})) > 0.2
          for: 1m
          labels:
            severity: critical
          annotations:
            description: '{{ $value }}% of Kubernetes nodes are not ready'
        - alert: K8SKubeletDown
          expr: count(up{job="kubelet"} == 0) / count(up{job="kubelet"}) * 100 > 3
          for: 1h
          labels:
            severity: warning
          annotations:
            description: Prometheus failed to scrape {{ $value }}% of kubelets.
        - alert: K8SKubeletDown
          expr: (absent(up{job="kubelet"} == 1) or count(up{job="kubelet"} == 0) / count(up{job="kubelet"}))
            * 100 > 10
          for: 1h
          labels:
            severity: critical
          annotations:
            description: Prometheus failed to scrape {{ $value }}% of kubelets, or all Kubelets
              have disappeared from service discovery.
            summary: Many Kubelets cannot be scraped
        - alert: K8SKubeletTooManyPods
          expr: kubelet_running_pod_count > 100
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Kubelet {{$labels.instance}} is running {{$value}} pods, close
              to the limit of 110
            summary: Kubelet is close to pod limit

      EOT
      "kubernetes.rules.yaml" = <<-EOT
      groups:
      - name: kubernetes.rules
        rules:
        - record: pod_name:container_memory_usage_bytes:sum
          expr: sum(container_memory_usage_bytes{container_name!="POD",pod_name!=""}) BY
            (pod_name)
        - record: pod_name:container_spec_cpu_shares:sum
          expr: sum(container_spec_cpu_shares{container_name!="POD",pod_name!=""}) BY (pod_name)
        - record: pod_name:container_cpu_usage:sum
          expr: sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name!=""}[5m]))
            BY (pod_name)
        - record: pod_name:container_fs_usage_bytes:sum
          expr: sum(container_fs_usage_bytes{container_name!="POD",pod_name!=""}) BY (pod_name)
        - record: namespace:container_memory_usage_bytes:sum
          expr: sum(container_memory_usage_bytes{container_name!=""}) BY (namespace)
        - record: namespace:container_spec_cpu_shares:sum
          expr: sum(container_spec_cpu_shares{container_name!=""}) BY (namespace)
        - record: namespace:container_cpu_usage:sum
          expr: sum(rate(container_cpu_usage_seconds_total{container_name!="POD"}[5m]))
            BY (namespace)
        - record: cluster:memory_usage:ratio
          expr: sum(container_memory_usage_bytes{container_name!="POD",pod_name!=""}) BY
            (cluster) / sum(machine_memory_bytes) BY (cluster)
        - record: cluster:container_spec_cpu_shares:ratio
          expr: sum(container_spec_cpu_shares{container_name!="POD",pod_name!=""}) / 1000
            / sum(machine_cpu_cores)
        - record: cluster:container_cpu_usage:ratio
          expr: sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name!=""}[5m]))
            / sum(machine_cpu_cores)
        - record: apiserver_latency_seconds:quantile
          expr: histogram_quantile(0.99, rate(apiserver_request_latencies_bucket[5m])) /
            1e+06
          labels:
            quantile: "0.99"
        - record: apiserver_latency:quantile_seconds
          expr: histogram_quantile(0.9, rate(apiserver_request_latencies_bucket[5m])) /
            1e+06
          labels:
            quantile: "0.9"
        - record: apiserver_latency_seconds:quantile
          expr: histogram_quantile(0.5, rate(apiserver_request_latencies_bucket[5m])) /
            1e+06
          labels:
            quantile: "0.5"
        - alert: APIServerLatencyHigh
          expr: apiserver_latency_seconds:quantile{quantile="0.99",subresource!="log",verb!~"^(?:WATCH|WATCHLIST|PROXY|CONNECT)$"}
            > 1
          for: 10m
          labels:
            severity: warning
          annotations:
            description: the API server has a 99th percentile latency of {{ $value }} seconds
              for {{$labels.verb}} {{$labels.resource}}
        - alert: APIServerLatencyHigh
          expr: apiserver_latency_seconds:quantile{quantile="0.99",subresource!="log",verb!~"^(?:WATCH|WATCHLIST|PROXY|CONNECT)$"}
            > 4
          for: 10m
          labels:
            severity: critical
          annotations:
            description: the API server has a 99th percentile latency of {{ $value }} seconds
              for {{$labels.verb}} {{$labels.resource}}
        - alert: APIServerErrorsHigh
          expr: rate(apiserver_request_count{code=~"^(?:5..)$"}[5m]) / rate(apiserver_request_count[5m])
            * 100 > 2
          for: 10m
          labels:
            severity: warning
          annotations:
            description: API server returns errors for {{ $value }}% of requests
        - alert: APIServerErrorsHigh
          expr: rate(apiserver_request_count{code=~"^(?:5..)$"}[5m]) / rate(apiserver_request_count[5m])
            * 100 > 5
          for: 10m
          labels:
            severity: critical
          annotations:
            description: API server returns errors for {{ $value }}% of requests
        - alert: K8SApiserverDown
          expr: absent(up{job="apiserver"} == 1)
          for: 20m
          labels:
            severity: critical
          annotations:
            description: No API servers are reachable or all have disappeared from service
              discovery

        - alert: K8sCertificateExpirationNotice
          labels:
            severity: warning
          annotations:
            description: Kubernetes API Certificate is expiring soon (less than 7 days)
          expr: sum(apiserver_client_certificate_expiration_seconds_bucket{le="604800"}) > 0

        - alert: K8sCertificateExpirationNotice
          labels:
            severity: critical
          annotations:
            description: Kubernetes API Certificate is expiring in less than 1 day
          expr: sum(apiserver_client_certificate_expiration_seconds_bucket{le="86400"}) > 0

      EOT
      "node.rules.yaml" = <<-EOT
      groups:
      - name: node.rules
        rules:
        - record: instance:node_cpu:rate:sum
          expr: sum(rate(node_cpu{mode!="idle",mode!="iowait",mode!~"^(?:guest.*)$"}[3m]))
            BY (instance)
        - record: instance:node_filesystem_usage:sum
          expr: sum((node_filesystem_size{mountpoint="/"} - node_filesystem_free{mountpoint="/"}))
            BY (instance)
        - record: instance:node_network_receive_bytes:rate:sum
          expr: sum(rate(node_network_receive_bytes[3m])) BY (instance)
        - record: instance:node_network_transmit_bytes:rate:sum
          expr: sum(rate(node_network_transmit_bytes[3m])) BY (instance)
        - record: instance:node_cpu:ratio
          expr: sum(rate(node_cpu{mode!="idle"}[5m])) WITHOUT (cpu, mode) / ON(instance)
            GROUP_LEFT() count(sum(node_cpu) BY (instance, cpu)) BY (instance)
        - record: cluster:node_cpu:sum_rate5m
          expr: sum(rate(node_cpu{mode!="idle"}[5m]))
        - record: cluster:node_cpu:ratio
          expr: cluster:node_cpu:rate5m / count(sum(node_cpu) BY (instance, cpu))
        - alert: NodeExporterDown
          expr: absent(up{job="node-exporter"} == 1)
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Prometheus could not scrape a node-exporter for more than 10m,
              or node-exporters have disappeared from discovery
        - alert: NodeDiskRunningFull
          expr: predict_linear(node_filesystem_free[6h], 3600 * 24) < 0
          for: 30m
          labels:
            severity: warning
          annotations:
            description: device {{$labels.device}} on node {{$labels.instance}} is running
              full within the next 24 hours (mounted at {{$labels.mountpoint}})
        - alert: NodeDiskRunningFull
          expr: predict_linear(node_filesystem_free[30m], 3600 * 2) < 0
          for: 10m
          labels:
            severity: critical
          annotations:
            description: device {{$labels.device}} on node {{$labels.instance}} is running
              full within the next 2 hours (mounted at {{$labels.mountpoint}})
        - alert: InactiveRAIDDisk
          expr: node_md_disks - node_md_disks_active > 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: '{{$value}} RAID disk(s) on node {{$labels.instance}} are inactive'

      EOT
      "prometheus.rules.yaml" = <<-EOT
      groups:
      - name: prometheus.rules
        rules:
        - alert: PrometheusConfigReloadFailed
          expr: prometheus_config_last_reload_successful == 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Reloading Prometheus' configuration has failed for {{$labels.namespace}}/{{$labels.pod}}
        - alert: PrometheusNotificationQueueRunningFull
          expr: predict_linear(prometheus_notifications_queue_length[5m], 60 * 30) > prometheus_notifications_queue_capacity
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Prometheus' alert notification queue is running full for {{$labels.namespace}}/{{
              $labels.pod}}
        - alert: PrometheusErrorSendingAlerts
          expr: rate(prometheus_notifications_errors_total[5m]) / rate(prometheus_notifications_sent_total[5m])
            > 0.01
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Errors while sending alerts from Prometheus {{$labels.namespace}}/{{
              $labels.pod}} to Alertmanager {{$labels.Alertmanager}}
        - alert: PrometheusErrorSendingAlerts
          expr: rate(prometheus_notifications_errors_total[5m]) / rate(prometheus_notifications_sent_total[5m])
            > 0.03
          for: 10m
          labels:
            severity: critical
          annotations:
            description: Errors while sending alerts from Prometheus {{$labels.namespace}}/{{
              $labels.pod}} to Alertmanager {{$labels.Alertmanager}}
        - alert: PrometheusNotConnectedToAlertmanagers
          expr: prometheus_notifications_alertmanagers_discovered < 1
          for: 10m
          labels:
            severity: warning
          annotations:
            description: Prometheus {{ $labels.namespace }}/{{ $labels.pod}} is not connected
              to any Alertmanagers
        - alert: PrometheusTSDBReloadsFailing
          expr: increase(prometheus_tsdb_reloads_failures_total[2h]) > 0
          for: 12h
          labels:
            severity: warning
          annotations:
            description: '{{$labels.job}} at {{$labels.instance}} had {{$value | humanize}}
              reload failures over the last four hours.'
            summary: Prometheus has issues reloading data blocks from disk
        - alert: PrometheusTSDBCompactionsFailing
          expr: increase(prometheus_tsdb_compactions_failed_total[2h]) > 0
          for: 12h
          labels:
            severity: warning
          annotations:
            description: '{{$labels.job}} at {{$labels.instance}} had {{$value | humanize}}
              compaction failures over the last four hours.'
            summary: Prometheus has issues compacting sample blocks
        - alert: PrometheusTSDBWALCorruptions
          expr: tsdb_wal_corruptions_total > 0
          for: 4h
          labels:
            severity: warning
          annotations:
            description: '{{$labels.job}} at {{$labels.instance}} has a corrupted write-ahead
              log (WAL).'
            summary: Prometheus write-ahead log is corrupted
        - alert: PrometheusNotIngestingSamples
          expr: rate(prometheus_tsdb_head_samples_appended_total[5m]) <= 0
          for: 10m
          labels:
            severity: warning
          annotations:
            description: "Prometheus {{ $labels.namespace }}/{{ $labels.pod}} isn't ingesting samples."
            summary: "Prometheus isn't ingesting samples"
      EOT
    }
}
resource "kubernetes_manifest" "serviceaccount_prometheus_metrics_prometheus" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "name" = "prometheus"
      "namespace" = "prometheus-metrics"
    }
  }
}
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "prometheus-metrics"
    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name        = "web"
      protocol    = "TCP"
      port        = 80
      target_port = "9090"
    }
    selector = {
      name = "prometheus"
    }
    type = "ClusterIP"
  }
}
resource "kubernetes_stateful_set" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "prometheus-metrics"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          name = "prometheus"
        }
      }
      spec {
        volume {
          name = "config"
          config_map {
            name         = "prometheus-config"
            default_mode = "0644"
          }
        }
        volume {
          name = "rules"
          config_map {
            name         = "prometheus-rules"
            default_mode = "0644"
          }
        }
        init_container {
          name    = "chown"
          image   = "docker.io/alpine:3.12"
          command = ["chown", "-R", "65534:65534", "/var/lib/prometheus"]
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/prometheus"
          }
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"
        }
        container {
          name  = "prometheus"
          image = "quay.io/prometheus/prometheus:v2.27.1"
          args  = [
            "--web.listen-address=0.0.0.0:9090",
            "--web.enable-lifecycle",
            "--config.file=/etc/prometheus/prometheus.yaml", 
            "--storage.tsdb.path=/var/lib/prometheus", 
            "--storage.tsdb.retention.time=2d", 
            "--storage.tsdb.retention.size=5GB", 
            "--storage.tsdb.min-block-duration=2h", 
            "--storage.tsdb.max-block-duration=2h"
          ]
          port {
            name           = "web"
            container_port = 9090
            protocol       = "TCP"
          }
          resources {
            requests = {
              cpu = "100m"
              memory = "512Mi"
            }
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/prometheus"
          }
          volume_mount {
            name       = "rules"
            mount_path = "/etc/prometheus/rules"
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/prometheus"
          }
          liveness_probe {
            http_get {
              path   = "/-/healthy"
              port   = "9090"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 10
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path   = "/-/ready"
              port   = "9090"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 10
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
        service_account_name             = "prometheus"
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/os"
                  operator = "In"
                  values   = ["linux"]
                }
              }
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "20G"
          }
        }
      }
    }
    service_name          = "prometheus"
    pod_management_policy = "OrderedReady"
    update_strategy {
      type = "RollingUpdate"
    }
    revision_history_limit = 10
  }
}
resource "kubernetes_cluster_role" "prometheus_metrics" {
  metadata {
    name = "prometheus-metrics"
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods", "ingresses", "configmaps"]
  }
  rule {
    verbs             = ["get"]
    non_resource_urls = ["/metrics"]
  }
}
resource "kubernetes_cluster_role_binding" "prometheus_metrics" {
  metadata {
    name = "prometheus-metrics"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "prometheus"
    namespace = "prometheus-metrics"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prometheus-metrics"
  }
}

resource "kubernetes_daemonset" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "prometheus-metrics"
  }
  spec {
    selector {
      match_labels = {
        name = "node-exporter"
        phase = "prod"
      }
    }
    template {
      metadata {
        labels = {
          name = "node-exporter"
          phase = "prod"
        }
      }
      spec {
        volume {
          name = "proc"
          host_path {
            path = "/proc"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "root"
          host_path {
            path = "/"
          }
        }
        container {
          name  = "node-exporter"
          image = "quay.io/prometheus/node-exporter:v1.1.2"
          args  = ["--path.procfs=/host/proc", "--path.sysfs=/host/sys", "--path.rootfs=/host/root", "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker|var/lib/containerd|var/lib/containers/.+)($|/)", "--collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$"]
          port {
            name           = "metrics"
            container_port = 9100
            protocol       = "TCP"
          }
          resources {
            limits = {
              cpu = "200m"
              memory = "100Mi"
            }
            requests = {
              cpu = "10m"
              memory = "24Mi"
            }
          }
          volume_mount {
            name       = "proc"
            read_only  = true
            mount_path = "/host/proc"
          }
          volume_mount {
            name       = "sys"
            read_only  = true
            mount_path = "/host/sys"
          }
          volume_mount {
            name       = "root"
            read_only  = true
            mount_path = "/host/root"
          }
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
        host_pid                         = true
        security_context {
          run_as_user     = 65534
          run_as_non_root = true
        }
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/os"
                  operator = "In"
                  values   = ["linux"]
                }
              }
            }
          }
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
      }
    }
    revision_history_limit = 10
  }
}
resource "kubernetes_service" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = "prometheus-metrics"
    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name        = "metrics"
      protocol    = "TCP"
      port        = 80
      target_port = "9100"
    }
    selector = {
      name = "node-exporter"
      phase = "prod"
    }
    type             = "ClusterIP"
    session_affinity = "None"
  }
}

resource "kubernetes_deployment" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = "prometheus-metrics"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "kube-state-metrics"
      }
    }
    template {
      metadata {
        labels = {
          name = "kube-state-metrics"
        }
      }
      spec {
        container {
          name  = "kube-state-metrics"
          image = "k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.7.0"
          port {
            name           = "metrics"
            container_port = 8080
            protocol       = "TCP"
          }
          resources {
            limits = {
              cpu = "200m"
              memory = "150Mi"
            }
            requests = {
              cpu = "10m"
              memory = "32Mi"
            }
          }
          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "8080"
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
        service_account_name             = "kube-state-metrics"
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/os"
                  operator = "In"
                  values   = ["linux"]
                }
              }
            }
          }
        }
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }
    revision_history_limit    = 10
    progress_deadline_seconds = 600
  }
}
resource "kubernetes_service" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = "prometheus-metrics"
    labels = {
      "app.kubernetes.io/name" = "prometheus-metrics"
      name = "kube-state-metrics"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name        = "metrics"
      protocol    = "TCP"
      port        = 8080
      target_port = "8080"
    }
    selector = {
      name = "kube-state-metrics"
    }
    type             = "ClusterIP"
    session_affinity = "None"
  }
}
resource "kubernetes_manifest" "serviceaccount_prometheus_metrics_kube_state_metrics" {
  computed_fields = ["secrets"]
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "name" = "kube-state-metrics"
      "namespace" = "prometheus-metrics"
    }
    "secrets" = [
      {
        "name" = "kube-state-metrics-token-5p8sm"
      },
    ]
  }
}
resource "kubernetes_cluster_role" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["networking","configmaps", "secrets", "nodes", "pods", "services", "resourcequotas", "replicationcontrollers", "limitranges", "persistentvolumeclaims", "persistentvolumes", "namespaces", "endpoints"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "replicasets", "ingresses"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["apps"]
    resources  = ["statefulsets", "daemonsets", "deployments", "replicasets"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies","ingresses"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
  }
}
resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
  metadata {
    name = "kube-state-metrics"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-state-metrics"
    namespace = "prometheus-metrics"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kube-state-metrics"
  }
}
