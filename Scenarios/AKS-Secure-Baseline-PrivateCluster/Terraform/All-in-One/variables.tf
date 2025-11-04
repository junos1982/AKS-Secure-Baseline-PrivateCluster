variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the resources will be created"
  type        = string
}

variable "prefix" {
  description = "Prefix used to construct resource names"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the private AKS cluster"
  type        = string
}

variable "environment" {
  description = "Name of the deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
}

variable "vnet_address_space" {
  description = "Address space for the AKS virtual network"
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to deploy"
  type        = string
}

variable "agent_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "agent_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 3
}

variable "agent_os_disk_size_gb" {
  description = "OS disk size for the system node pool"
  type        = number
  default     = 128
}

variable "user_node_vm_size" {
  description = "VM size for the user node pool"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "user_node_count" {
  description = "Number of nodes in the user node pool"
  type        = number
  default     = 3
}

variable "user_node_os_disk_size_gb" {
  description = "OS disk size in GB for the user node pool"
  type        = number
  default     = 128
}

variable "user_node_max_pods" {
  description = "Maximum pods per node for the user node pool"
  type        = number
  default     = 30
}

variable "admin_username" {
  description = "Admin username for Linux nodes"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for Linux nodes"
  type        = string
}

variable "authorized_ip_ranges" {
  description = "List of CIDRs that are allowed to access the Kubernetes API server"
  type        = list(string)
  default     = []
}

variable "service_cidr" {
  description = "Network range for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "docker_bridge_cidr" {
  description = "CIDR for the Docker bridge network"
  type        = string
  default     = "172.17.0.1/16"
}
