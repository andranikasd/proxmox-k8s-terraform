# Example usage of the proxmox-k8s-terraform module

terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Configure the Proxmox Provider
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# SSH Configuration
variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Use the module
module "kubernetes_cluster" {
  source = "../"

  # Proxmox Configuration
  proxmox_api_url          = var.proxmox_api_url
  proxmox_token_id         = var.proxmox_token_id
  proxmox_token_secret     = var.proxmox_token_secret
  proxmox_tls_insecure     = var.proxmox_tls_insecure
  proxmox_node_name        = var.proxmox_node_name
  proxmox_datastore        = var.proxmox_datastore
  proxmox_template         = var.proxmox_template
  proxmox_bridge           = var.proxmox_bridge

  # SSH Configuration
  ssh_private_key_path = var.ssh_private_key_path

  # Kubernetes Cluster Configuration
  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  container_runtime    = var.container_runtime
  pod_cidr            = var.pod_cidr
  service_cidr        = var.service_cidr
  cluster_dns         = var.cluster_dns
  load_balancer_ip    = var.load_balancer_ip

  # Node Configuration
  master_count        = var.master_count
  worker_count        = var.worker_count

  # Master Node Resources
  master_cpu_cores    = var.master_cpu_cores
  master_memory       = var.master_memory
  master_disk_size    = var.master_disk_size

  # Worker Node Resources
  worker_cpu_cores    = var.worker_cpu_cores
  worker_memory       = var.worker_memory
  worker_disk_size    = var.worker_disk_size

  # VM Access Configuration
  vm_username         = var.vm_username
  vm_password         = var.vm_password
  ssh_public_key      = var.ssh_public_key
}

# Outputs
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubernetes_cluster.cluster_name
}

output "master_nodes" {
  description = "Information about master nodes"
  value       = module.kubernetes_cluster.master_nodes
}

output "worker_nodes" {
  description = "Information about worker nodes"
  value       = module.kubernetes_cluster.worker_nodes
}

output "connection_info" {
  description = "Information for connecting to the cluster"
  value       = module.kubernetes_cluster.connection_info
  sensitive   = true
}
