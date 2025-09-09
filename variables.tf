# Proxmox Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
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
}

variable "proxmox_datastore" {
  description = "Proxmox datastore for VM storage"
  type        = string
}

variable "proxmox_template" {
  description = "Proxmox template to clone for VMs"
  type        = string
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

# Flux GitOps Configuration
variable "enable_flux" {
  description = "Enable Flux GitOps deployment"
  type        = bool
  default     = false
}

variable "flux_github_repository" {
  description = "GitHub repository for Flux GitOps (format: owner/repo)"
  type        = string
  default     = ""
}

variable "flux_github_branch" {
  description = "GitHub branch for Flux GitOps"
  type        = string
  default     = "main"
}

variable "flux_github_path" {
  description = "Path within the repository for Flux to watch"
  type        = string
  default     = "./clusters/production"
}

variable "flux_github_token" {
  description = "GitHub personal access token for Flux"
  type        = string
  sensitive   = true
  default     = ""
}

variable "flux_namespace" {
  description = "Kubernetes namespace for Flux"
  type        = string
  default     = "flux-system"
}

variable "flux_version" {
  description = "Flux version to install"
  type        = string
  default     = "2.0.1"
}

# Load Balancer and Networking Configuration
variable "enable_metallb" {
  description = "Enable MetalLB load balancer"
  type        = bool
  default     = false
}

variable "metallb_ip_range" {
  description = "IP range for MetalLB load balancer (e.g., '192.168.1.100-192.168.1.110')"
  type        = string
  default     = ""
}

variable "enable_kubevip" {
  description = "Enable KubeVIP for API server load balancing"
  type        = bool
  default     = false
}

variable "kubevip_version" {
  description = "KubeVIP version to install"
  type        = string
  default     = "0.6.4"
}

variable "api_server_vip" {
  description = "Virtual IP for Kubernetes API server"
  type        = string
  default     = ""
}

variable "enable_ingress_nginx" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "ingress_nginx_version" {
  description = "NGINX Ingress Controller version"
  type        = string
  default     = "1.8.2"
}

variable "public_ip" {
  description = "Public IP address of the OVH server for load balancer services"
  type        = string
  default     = ""
}

# Kubernetes Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
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
  validation {
    condition     = contains(["containerd", "docker"], var.container_runtime)
    error_message = "Container runtime must be either 'containerd' or 'docker'."
  }
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
  validation {
    condition     = var.master_count >= 1 && var.master_count <= 5
    error_message = "Master count must be between 1 and 5."
  }
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.worker_count >= 1
    error_message = "Worker count must be at least 1."
  }
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
}
