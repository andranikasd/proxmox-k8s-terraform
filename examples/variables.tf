# Example variables for the proxmox-k8s-terraform module

# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://your-proxmox-server:8006/api2/json"
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = false
}

variable "proxmox_node_name" {
  description = "Proxmox node name where VMs will be created"
  type        = string
  default     = "pve"
}

variable "proxmox_datastore" {
  description = "Proxmox datastore for VM storage"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_template" {
  description = "Proxmox template to clone for VMs"
  type        = string
  default     = "ubuntu-22.04-cloud"
}

variable "proxmox_bridge" {
  description = "Proxmox bridge for VM networking"
  type        = string
  default     = "vmbr0"
}

# SSH Configuration
variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Kubernetes Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "my-k8s-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28.0"
}

variable "container_runtime" {
  description = "Container runtime to use (containerd, docker)"
  type        = string
  default     = "containerd"
}

variable "pod_cidr" {
  description = "CIDR block for pod networks"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for service networks"
  type        = string
  default     = "10.96.0.0/12"
}

variable "cluster_dns" {
  description = "Cluster DNS IP address"
  type        = string
  default     = "10.96.0.10"
}

variable "load_balancer_ip" {
  description = "Load balancer IP for the cluster"
  type        = string
  default     = ""
}

# Node Configuration
variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

# Master Node Resources
variable "master_cpu_cores" {
  description = "Number of CPU cores for master nodes"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "Memory in MB for master nodes"
  type        = number
  default     = 4096
}

variable "master_disk_size" {
  description = "Disk size in GB for master nodes"
  type        = number
  default     = 50
}

# Worker Node Resources
variable "worker_cpu_cores" {
  description = "Number of CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
  default     = 4096
}

variable "worker_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

# VM Access Configuration
variable "vm_username" {
  description = "Username for VM access"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "Password for VM access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7..."
}
