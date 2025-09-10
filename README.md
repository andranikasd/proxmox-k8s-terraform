# Proxmox Kubernetes Terraform Module

Terraform module that deploys a Kubernetes cluster on Proxmox using cloud-init and remote-exec provisioners for configuration management.

## Features

- **Proxmox Integration**: Creates VMs on Proxmox with configurable resources
- **Cloud-init Configuration**: Uses cloud-init for automated VM setup and Kubernetes installation
- **Flexible Architecture**: Supports both single and multi-master configurations
- **Container Runtime Options**: Supports both containerd and Docker
- **Network Configuration**: Configurable pod and service CIDR ranges
- **Resource Management**: Configurable CPU, memory, and disk resources
- **Flux GitOps Integration**: Optional Flux deployment with GitHub repository connection
- **Load Balancer Support**: MetalLB and KubeVIP for exposing services with public IPs
- **Ingress Controller**: NGINX Ingress Controller for HTTP/HTTPS routing

## Architecture

This module creates:
- **Master Nodes**: Kubernetes control plane nodes
- **Worker Nodes**: Kubernetes worker nodes
- **Cloud-init Configuration**: Automated VM setup and Kubernetes installation
- **Network Setup**: CNI plugin installation and configuration
- **Flux GitOps**: Optional GitOps deployment with GitHub integration
- **Load Balancers**: MetalLB for LoadBalancer services, KubeVIP for API server
- **Ingress**: NGINX Ingress Controller for external access

## Prerequisites

### Proxmox Setup
1. Proxmox server with API access
2. API token with appropriate permissions
3. **Ubuntu 22.04 Cloud Template** (see manual creation guide below)
4. Network bridge configured

### Manual Template Creation

Before using this module, you need to create an Ubuntu 22.04 cloud template on your Proxmox server. Follow these steps:

#### Step 1: Access Proxmox CLI
SSH into your Proxmox server or use the web interface shell.

#### Step 2: Download Ubuntu 22.04 Cloud Image
```bash
# Download the latest Ubuntu 22.04 LTS cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

#### Step 3: Install Required Tools
```bash
# Update package list and install libguestfs-tools
apt update -y
apt install libguestfs-tools -y
```

#### Step 4: Inject QEMU Guest Agent
```bash
# Inject the qemu-guest-agent into the image
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent
```

#### Step 5: Create VM Template
```bash
# Get next available VMID (or use a specific one like 9000)
VMID=$(pvesh get /cluster/nextid)

# Create VM with basic configuration
qm create $VMID --name "ubuntu-22.04-cloud" --memory 1024 --cores 1 --net0 virtio,bridge=vmbr0

# Import the cloud image as a qcow2 disk
qm importdisk $VMID jammy-server-cloudimg-amd64.img local-lvm --format qcow2

# Attach the disk to the VM
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:$VMID/vm-$VMID-disk-0.qcow2

# Configure VM settings
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1

# Convert VM to template
qm template $VMID

echo "Template created successfully with VMID: $VMID"
```

#### Step 6: Verify Template Creation
```bash
# List all templates to verify creation
qm list | grep template
```

The template should now be available as `ubuntu-22.04-cloud` and ready for use with this Terraform module.

### Flux GitOps Setup (Optional)
1. GitHub repository for GitOps configuration
2. GitHub personal access token with repository permissions
3. Repository structure with cluster configuration path

## Usage

### Basic Example

```hcl
module "kubernetes_cluster" {
  source = "path/to/proxmox-k8s-terraform"

  # Proxmox Configuration
  proxmox_api_url      = "https://your-proxmox:8006/api2/json"
  proxmox_token_id     = "terraform@pve!terraform-token"
  proxmox_token_secret = "your-token-secret"
  proxmox_node_name    = "pve"
  proxmox_datastore    = "local-lvm"
  proxmox_template     = "ubuntu-22.04-cloud"

  # SSH Configuration
  ssh_private_key_path = "~/.ssh/id_rsa"

  # Kubernetes Configuration
  cluster_name       = "my-k8s-cluster"
  kubernetes_version = "1.28.0"
  master_count       = 1
  worker_count       = 2
  pod_cidr          = "10.244.0.0/16"
  service_cidr      = "10.96.0.0/12"

  # VM Access
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

### With Flux GitOps

```hcl
module "kubernetes_cluster" {
  source = "path/to/proxmox-k8s-terraform"

  # Proxmox Configuration
  proxmox_api_url      = "https://your-proxmox:8006/api2/json"
  proxmox_token_id     = "terraform@pve!terraform-token"
  proxmox_token_secret = "your-token-secret"
  proxmox_node_name    = "pve"
  proxmox_datastore    = "local-lvm"
  proxmox_template     = "ubuntu-22.04-cloud"

  # SSH Configuration
  ssh_private_key_path = "~/.ssh/id_rsa"

  # Kubernetes Configuration
  cluster_name       = "my-k8s-cluster"
  kubernetes_version = "1.28.0"
  master_count       = 1
  worker_count       = 2
  pod_cidr          = "10.244.0.0/16"
  service_cidr      = "10.96.0.0/12"

  # Flux GitOps Configuration
  enable_flux = true
  flux_github_repository = "your-username/your-gitops-repo"
  flux_github_branch = "main"
  flux_github_path = "./clusters/production"
  flux_github_token = "your-github-token"
  flux_version = "2.0.1"

  # VM Access
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

### With Load Balancers and Ingress

```hcl
module "kubernetes_cluster" {
  source = "path/to/proxmox-k8s-terraform"

  # Proxmox Configuration
  proxmox_api_url      = "https://your-proxmox:8006/api2/json"
  proxmox_token_id     = "terraform@pve!terraform-token"
  proxmox_token_secret = "your-token-secret"
  proxmox_node_name    = "pve"
  proxmox_datastore    = "local-lvm"
  proxmox_template     = "ubuntu-22.04-cloud"

  # SSH Configuration
  ssh_private_key_path = "~/.ssh/id_rsa"

  # Kubernetes Configuration
  cluster_name       = "my-k8s-cluster"
  kubernetes_version = "1.28.0"
  master_count       = 1
  worker_count       = 2
  pod_cidr          = "10.244.0.0/16"
  service_cidr      = "10.96.0.0/12"

  # Load Balancer and Networking Configuration
  enable_metallb = true
  metallb_ip_range = "192.168.1.100-192.168.1.110"
  enable_kubevip = true
  api_server_vip = "192.168.1.100"
  enable_ingress_nginx = true
  public_ip = "YOUR_PUBLIC_IP"

  # VM Access
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

### Advanced Configuration

```hcl
module "kubernetes_cluster" {
  source = "path/to/proxmox-k8s-terraform"

  # Proxmox Configuration
  proxmox_api_url          = "https://your-proxmox:8006/api2/json"
  proxmox_token_id         = "terraform@pve!terraform-token"
  proxmox_token_secret     = "your-token-secret"
  proxmox_tls_insecure     = false
  proxmox_node_name        = "pve"
  proxmox_datastore        = "local-lvm"
  proxmox_template         = "ubuntu-22.04-cloud"
  proxmox_bridge           = "vmbr0"

  # VM Access Configuration
  ssh_private_key_path = "~/.ssh/id_rsa"
  ssh_public_key       = file("~/.ssh/id_rsa.pub")
  vm_username          = "ubuntu"
  vm_password          = "SecurePassword123!"

  # Kubernetes Configuration
  cluster_name         = "production-k8s"
  kubernetes_version   = "1.28.0"
  container_runtime    = "containerd"
  pod_cidr            = "10.244.0.0/16"
  service_cidr        = "10.96.0.0/12"
  cluster_dns         = "10.96.0.10"
  load_balancer_ip    = "192.168.1.100"

  # High Availability Configuration
  master_count = 3
  worker_count = 5

  # Master Node Resources
  master_cpu_cores = 4
  master_memory    = 8192
  master_disk_size = 100

  # Worker Node Resources
  worker_cpu_cores = 4
  worker_memory    = 8192
  worker_disk_size = 100

  # VM Access
  vm_username    = "ubuntu"
  vm_password    = "secure-password"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

## Input Variables

### Proxmox Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| proxmox_api_url | Proxmox API URL | `string` | n/a | yes |
| proxmox_token_id | Proxmox API token ID | `string` | n/a | yes |
| proxmox_token_secret | Proxmox API token secret | `string` | n/a | yes |
| proxmox_tls_insecure | Skip TLS verification | `bool` | `false` | no |
| proxmox_node_name | Proxmox node name | `string` | n/a | yes |
| proxmox_datastore | Proxmox datastore | `string` | n/a | yes |
| proxmox_template | Proxmox template | `string` | n/a | yes |
| proxmox_bridge | Proxmox bridge | `string` | `"vmbr0"` | no |

### SSH Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ssh_private_key_path | Path to SSH private key | `string` | `"~/.ssh/id_rsa"` | no |

### Flux GitOps Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_flux | Enable Flux GitOps deployment | `bool` | `false` | no |
| flux_github_repository | GitHub repository (owner/repo) | `string` | `""` | no |
| flux_github_branch | GitHub branch | `string` | `"main"` | no |
| flux_github_path | Repository path to watch | `string` | `"./clusters/production"` | no |
| flux_github_token | GitHub personal access token | `string` | `""` | no |
| flux_namespace | Kubernetes namespace for Flux | `string` | `"flux-system"` | no |
| flux_version | Flux version to install | `string` | `"2.0.1"` | no |

### Load Balancer and Networking Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_metallb | Enable MetalLB load balancer | `bool` | `false` | no |
| metallb_ip_range | IP range for MetalLB | `string` | `""` | no |
| enable_kubevip | Enable KubeVIP for API server | `bool` | `false` | no |
| kubevip_version | KubeVIP version | `string` | `"0.6.4"` | no |
| api_server_vip | Virtual IP for API server | `string` | `""` | no |
| enable_ingress_nginx | Enable NGINX Ingress Controller | `bool` | `false` | no |
| ingress_nginx_version | NGINX Ingress version | `string` | `"1.8.2"` | no |
| public_ip | Public IP for load balancer services | `string` | `""` | no |

### Kubernetes Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Cluster name | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.28.0"` | no |
| container_runtime | Container runtime | `string` | `"containerd"` | no |
| pod_cidr | Pod CIDR | `string` | `"10.244.0.0/16"` | no |
| service_cidr | Service CIDR | `string` | `"10.96.0.0/12"` | no |
| cluster_dns | Cluster DNS IP | `string` | `"10.96.0.10"` | no |
| load_balancer_ip | Load balancer IP | `string` | `""` | no |

### Node Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| master_count | Number of master nodes | `number` | `1` | no |
| worker_count | Number of worker nodes | `number` | `2` | no |
| master_cpu_cores | Master CPU cores | `number` | `2` | no |
| master_memory | Master memory (MB) | `number` | `4096` | no |
| master_disk_size | Master disk size (GB) | `number` | `50` | no |
| worker_cpu_cores | Worker CPU cores | `number` | `2` | no |
| worker_memory | Worker memory (MB) | `number` | `4096` | no |
| worker_disk_size | Worker disk size (GB) | `number` | `50` | no |

### VM Access Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vm_username | VM username | `string` | `"ubuntu"` | no |
| vm_password | VM password | `string` | `""` | no |
| ssh_public_key | SSH public key | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the Kubernetes cluster |
| master_nodes | Information about master nodes |
| worker_nodes | Information about worker nodes |
| pod_cidr | CIDR block for pod networks |
| service_cidr | CIDR block for service networks |
| cluster_dns | Cluster DNS IP address |
| connection_info | Information for connecting to the cluster |
| flux_enabled | Whether Flux GitOps is enabled |
| flux_github_repository | GitHub repository configured for Flux |
| flux_github_branch | GitHub branch configured for Flux |
| flux_github_path | GitHub path configured for Flux |
| flux_namespace | Kubernetes namespace for Flux |
| flux_version | Flux version installed |
| kubeconfig_path | Path to the local kubeconfig file |
| kubeconfig_usage | Instructions for using the kubeconfig |
| master_node_ip | IP address of the first master node |
| metallb_enabled | Whether MetalLB is enabled |
| metallb_ip_range | IP range configured for MetalLB |
| kubevip_enabled | Whether KubeVIP is enabled |
| api_server_vip | Virtual IP for Kubernetes API server |
| ingress_nginx_enabled | Whether NGINX Ingress Controller is enabled |
| public_ip | Public IP address for load balancer services |
| networking_info | Networking configuration summary |

## Cloud-init Configuration

This module uses cloud-init for automated VM setup:
- **System configuration**: Package installation, kernel modules, sysctl settings
- **Container runtime**: containerd or Docker installation
- **Kubernetes packages**: kubelet, kubeadm, kubectl installation
- **Flux CLI**: Optional Flux CLI installation for GitOps
- **Network setup**: CNI plugins and Flannel configuration

### Template Structure
```
templates/
└── cloud-init.yaml
```

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd proxmox-k8s-terraform
   ```

2. **Set up Proxmox API token**:
   - Create a token in Proxmox web interface
   - Note the token ID and secret

3. **Set up Flux GitOps (optional)**:
   - Create a GitHub repository for GitOps configuration
   - Generate a GitHub personal access token
   - Set up repository structure with cluster configuration

4. **Configure variables**:
   ```bash
   cp examples/terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

5. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

6. **Access the cluster**:
   ```bash
   # The kubeconfig is automatically extracted and saved locally
   # Check the Terraform outputs for the kubeconfig path
   terraform output kubeconfig_path
   terraform output kubeconfig_usage
   
   # Use the kubeconfig
   export KUBECONFIG=./kubeconfig/kubeconfig-<cluster-name>
   kubectl get nodes
   kubectl get pods --all-namespaces
   
   # Alternative: SSH to master node
   ssh ubuntu@<master-node-ip>
   kubectl get nodes
   ```

## Troubleshooting

### Common Issues

1. **VM creation fails**: Check Proxmox API permissions and resource availability
2. **Flux installation fails**: Verify GitHub token permissions and repository access
3. **Kubernetes initialization fails**: Check network connectivity and resource constraints
4. **CNI plugin issues**: Verify pod CIDR configuration and network setup

### Logs

- **Terraform logs**: Use `TF_LOG=DEBUG terraform apply`
- **Cloud-init logs**: Check `/var/log/cloud-init-output.log` on VMs
- **Kubernetes logs**: Check `/var/log/kubernetes/` on master nodes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the Flux documentation
