# GENERAL
variable "cluster_name" {
  description = "(Required) - The name of the cluster."
  type        = string
}

variable "kubeconfig_path" {
  description = "(Optional) - path of kubeconfig file ( default ./kubeconfig.yaml)"
  type        = string
  default     = "./kubeconfig.yml"
}

variable "istio_password" {
  description = "The Password used for istio"
  type        = string
  sensitive   = true
}

