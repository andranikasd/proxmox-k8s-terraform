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
