# Proxmox Kubernetes Terraform Module

Terraform module that deploys a Kubernetes cluster on Proxmox using Chef for configuration management.

## Features

- **Proxmox Integration**: Creates VMs on Proxmox with configurable resources
- **Chef Configuration**: Uses Chef cookbooks for automated Kubernetes setup
- **Flexible Architecture**: Supports both single and multi-master configurations
- **Container Runtime Options**: Supports both containerd and Docker
- **Network Configuration**: Configurable pod and service CIDR ranges
- **Resource Management**: Configurable CPU, memory, and disk resources

## Architecture

This module creates:
- **Master Nodes**: Kubernetes control plane nodes
- **Worker Nodes**: Kubernetes worker nodes
- **Chef Integration**: Automated configuration management
- **Network Setup**: CNI plugin installation and configuration

## Prerequisites

### Proxmox Setup
1. Proxmox server with API access
2. API token with appropriate permissions
3. VM template (Ubuntu 20.04+ recommended)
4. Network bridge configured

### Chef Setup
1. Chef server with API access
2. Chef client with appropriate permissions
3. Kubernetes cookbook uploaded to Chef server

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

  # Chef Configuration
  chef_server_url  = "https://your-chef-server/organizations/your-org"
  chef_client_name = "terraform-client"
  chef_private_key = file("~/.chef/terraform-client.pem")

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

  # Chef Configuration
  chef_server_url  = "https://your-chef-server/organizations/your-org"
  chef_client_name = "terraform-client"
  chef_private_key = file("~/.chef/terraform-client.pem")
  chef_environment = "production"

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

### Chef Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chef_server_url | Chef server URL | `string` | n/a | yes |
| chef_client_name | Chef client name | `string` | n/a | yes |
| chef_private_key | Chef private key | `string` | n/a | yes |
| chef_environment | Chef environment | `string` | `"_default"` | no |

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

## Chef Cookbooks

This module includes Chef cookbooks for:
- **Common setup**: System configuration, package installation
- **Container runtime**: containerd or Docker installation
- **Kubernetes packages**: kubelet, kubeadm, kubectl installation
- **Master configuration**: Control plane setup
- **Worker configuration**: Worker node setup

### Cookbook Structure
```
cookbooks/kubernetes/
├── metadata.rb
├── attributes/
│   └── default.rb
├── recipes/
│   ├── default.rb
│   ├── common.rb
│   ├── packages.rb
│   ├── containerd.rb
│   ├── master.rb
│   └── worker.rb
└── templates/
    └── containerd-config.toml.erb
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

3. **Set up Chef server**:
   - Upload the Kubernetes cookbook to your Chef server
   - Create a Chef client for Terraform

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
   # SSH to master node
   ssh ubuntu@<master-node-ip>
   
   # Copy kubeconfig
   sudo cp /etc/kubernetes/admin.conf ~/.kube/config
   sudo chown ubuntu:ubuntu ~/.kube/config
   
   # Verify cluster
   kubectl get nodes
   ```

## Troubleshooting

### Common Issues

1. **VM creation fails**: Check Proxmox API permissions and resource availability
2. **Chef node registration fails**: Verify Chef server connectivity and credentials
3. **Kubernetes initialization fails**: Check network connectivity and resource constraints
4. **CNI plugin issues**: Verify pod CIDR configuration and network setup

### Logs

- **Terraform logs**: Use `TF_LOG=DEBUG terraform apply`
- **Chef logs**: Check `/var/log/chef/client.log` on VMs
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
- Review the Chef cookbook documentation
