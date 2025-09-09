# Cluster Information
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "kubernetes_version" {
  description = "Kubernetes version installed"
  value       = var.kubernetes_version
}

# Master Nodes
output "master_nodes" {
  description = "Information about master nodes"
  value = {
    count = var.master_count
    names = [for i in range(var.master_count) : proxmox_virtual_environment_vm.master_nodes[i].name]
    vm_ids = [for i in range(var.master_count) : proxmox_virtual_environment_vm.master_nodes[i].vm_id]
  }
}

# Worker Nodes
output "worker_nodes" {
  description = "Information about worker nodes"
  value = {
    count = var.worker_count
    names = [for i in range(var.worker_count) : proxmox_virtual_environment_vm.worker_nodes[i].name]
    vm_ids = [for i in range(var.worker_count) : proxmox_virtual_environment_vm.worker_nodes[i].vm_id]
  }
}

# Network Configuration
output "pod_cidr" {
  description = "CIDR block for pod networks"
  value       = var.pod_cidr
}

output "service_cidr" {
  description = "CIDR block for service networks"
  value       = var.service_cidr
}

output "cluster_dns" {
  description = "Cluster DNS IP address"
  value       = var.cluster_dns
}

# Proxmox Information
output "proxmox_node" {
  description = "Proxmox node where VMs are deployed"
  value       = var.proxmox_node_name
}

output "proxmox_datastore" {
  description = "Proxmox datastore used for VMs"
  value       = var.proxmox_datastore
}

# SSH Information
output "ssh_private_key_path" {
  description = "Path to SSH private key for VM access"
  value       = var.ssh_private_key_path
}

# Flux GitOps Information
output "flux_enabled" {
  description = "Whether Flux GitOps is enabled"
  value       = var.enable_flux
}

output "flux_github_repository" {
  description = "GitHub repository configured for Flux"
  value       = var.enable_flux ? var.flux_github_repository : null
}

output "flux_github_branch" {
  description = "GitHub branch configured for Flux"
  value       = var.enable_flux ? var.flux_github_branch : null
}

output "flux_github_path" {
  description = "GitHub path configured for Flux"
  value       = var.enable_flux ? var.flux_github_path : null
}

output "flux_namespace" {
  description = "Kubernetes namespace for Flux"
  value       = var.enable_flux ? var.flux_namespace : null
}

output "flux_version" {
  description = "Flux version installed"
  value       = var.enable_flux ? var.flux_version : null
}

# Connection Information
output "connection_info" {
  description = "Information for connecting to the cluster"
  value = {
    ssh_username = var.vm_username
    master_nodes = [for i in range(var.master_count) : proxmox_virtual_environment_vm.master_nodes[i].name]
    worker_nodes = [for i in range(var.worker_count) : proxmox_virtual_environment_vm.worker_nodes[i].name]
  }
  sensitive = true
}

# Kubeconfig Information
output "kubeconfig_path" {
  description = "Path to the local kubeconfig file"
  value       = "./kubeconfig/kubeconfig-${var.cluster_name}"
}

output "kubeconfig_usage" {
  description = "Instructions for using the kubeconfig"
  value = <<-EOT
    To use this kubeconfig:
    1. export KUBECONFIG=./kubeconfig/kubeconfig-${var.cluster_name}
    2. kubectl get nodes
    3. kubectl get pods --all-namespaces
  EOT
}

output "master_node_ip" {
  description = "IP address of the first master node"
  value       = data.external.master_ips[0].result.ip
}

# Load Balancer and Networking Information
output "metallb_enabled" {
  description = "Whether MetalLB is enabled"
  value       = var.enable_metallb
}

output "metallb_ip_range" {
  description = "IP range configured for MetalLB"
  value       = var.enable_metallb ? var.metallb_ip_range : null
}

output "kubevip_enabled" {
  description = "Whether KubeVIP is enabled"
  value       = var.enable_kubevip
}

output "api_server_vip" {
  description = "Virtual IP for Kubernetes API server"
  value       = var.enable_kubevip ? var.api_server_vip : null
}

output "ingress_nginx_enabled" {
  description = "Whether NGINX Ingress Controller is enabled"
  value       = var.enable_ingress_nginx
}

output "public_ip" {
  description = "Public IP address for load balancer services"
  value       = var.public_ip
}

output "networking_info" {
  description = "Networking configuration summary"
  value = {
    public_ip = var.public_ip
    metallb_enabled = var.enable_metallb
    metallb_ip_range = var.metallb_ip_range
    kubevip_enabled = var.enable_kubevip
    api_server_vip = var.api_server_vip
    ingress_nginx_enabled = var.enable_ingress_nginx
    pod_cidr = var.pod_cidr
    service_cidr = var.service_cidr
  }
}
