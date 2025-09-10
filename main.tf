terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

# Proxmox provider configuration
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# Local values for cloud-init configuration
locals {
  cloud_init_config = templatefile("${path.module}/templates/cloud-init.yaml", {
    vm_username           = var.vm_username
    vm_password           = var.vm_password
    ssh_public_key        = var.ssh_public_key
    kubernetes_version    = var.kubernetes_version
    container_runtime     = var.container_runtime
    cluster_dns           = var.cluster_dns
    pod_cidr              = var.pod_network_cidr
    service_cidr          = var.service_cidr
    enable_flux           = var.enable_flux
    flux_github_repository = var.flux_github_repository
    flux_github_branch    = var.flux_github_branch
    flux_github_path      = var.flux_github_path
    flux_github_token     = var.flux_github_token
    flux_namespace        = var.flux_namespace
    flux_version          = var.flux_version
    enable_metallb        = var.enable_metallb
    metallb_ip_range      = var.metallb_ip_range
    enable_kubevip        = var.enable_kubevip
    kubevip_version       = var.kubevip_version
  })
}

# Upload cloud-init configuration to Proxmox
resource "null_resource" "upload_cloud_init" {
  provisioner "local-exec" {
    command = <<-EOT
      # Create cloud-init file
      cat > /tmp/kubernetes-cloud-init.yaml << 'EOF'
${local.cloud_init_config}
EOF
      
      # Upload to Proxmox snippets
      curl -k -H "Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token_secret}" \
           -F "filename=kubernetes-cloud-init.yaml" \
           -F "content=@/tmp/kubernetes-cloud-init.yaml" \
           "${var.proxmox_api_url}/nodes/${var.proxmox_node_name}/snippets"
    EOT
  }
}

# Create master nodes
resource "proxmox_vm_qemu" "master_nodes" {
  count = var.master_count
  depends_on = [null_resource.upload_cloud_init]

  name    = "${var.cluster_name}-master-${count.index + 1}"
  description = "Kubernetes master node ${count.index + 1}"
  target_node = var.proxmox_node_name

  # VM Configuration
  cores   = var.master_cpu_cores
  memory  = var.master_memory
  sockets = 1

  # Disk configuration
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.proxmox_datastore
    size    = "${var.master_disk_size}G"
    format  = "qcow2"
  }

  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Cloud-init configuration
  ciuser     = var.vm_username
  cipassword = var.vm_password
  sshkeys    = var.ssh_public_key

  # Clone from template
  clone = var.proxmox_template

  # Cloud-init configuration
  cicustom = "user=${var.proxmox_datastore}:snippets/kubernetes-cloud-init.yaml"

  # Agent
  agent = 1

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Create worker nodes
resource "proxmox_vm_qemu" "worker_nodes" {
  count = var.worker_count
  depends_on = [null_resource.upload_cloud_init]

  name    = "${var.cluster_name}-worker-${count.index + 1}"
  description = "Kubernetes worker node ${count.index + 1}"
  target_node = var.proxmox_node_name

  # VM Configuration
  cores   = var.worker_cpu_cores
  memory  = var.worker_memory
  sockets = 1

  # Disk configuration
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.proxmox_datastore
    size    = "${var.worker_disk_size}G"
    format  = "qcow2"
  }

  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  # Cloud-init configuration
  ciuser     = var.vm_username
  cipassword = var.vm_password
  sshkeys    = var.ssh_public_key

  # Clone from template
  clone = var.proxmox_template

  # Cloud-init configuration
  cicustom = "user=${var.proxmox_datastore}:snippets/kubernetes-cloud-init.yaml"

  # Agent
  agent = 1

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Wait for VMs to be ready
resource "time_sleep" "wait_for_vms" {
  depends_on = [
    proxmox_vm_qemu.master_nodes,
    proxmox_vm_qemu.worker_nodes
  ]

  create_duration = "300s"
}

# Get master node IPs using Proxmox API
data "external" "master_ips" {
  count = var.master_count
  depends_on = [time_sleep.wait_for_vms]
  
  program = ["bash", "-c", <<-EOT
    curl -k -H "Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token_secret}" \
         "${var.proxmox_api_url}/nodes/${var.proxmox_node_name}/qemu/${proxmox_vm_qemu.master_nodes[count.index].vmid}/agent/network-get-interfaces" \
         2>/dev/null | jq -r '.data.result[] | select(.name=="eth0") | .["ip-addresses"][] | select(.["ip-address-type"]=="ipv4") | .["ip-address"]' | head -1
  EOT
  ]
}

# Initialize Kubernetes cluster on first master node
resource "null_resource" "kubeadm_init" {
  depends_on = [time_sleep.wait_for_vms]

  connection {
    type        = "ssh"
    host        = data.external.master_ips[0].result.ip
    user        = var.vm_username
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # Initialize Kubernetes cluster
      "sudo kubeadm init --pod-network-cidr=${var.pod_network_cidr} --apiserver-advertise-address=${data.external.master_ips[0].result.ip}",
      
      # Setup kubectl for ubuntu user
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      
      # Install Flannel CNI
      "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml",
      
      # Install Flux (if enabled)
      var.enable_flux ? "curl -s https://fluxcd.io/install.sh | sudo bash" : "echo 'Flux installation skipped'",
      var.enable_flux && var.flux_github_repository != "" ? "flux bootstrap github --owner=${split("/", var.flux_github_repository)[0]} --repository=${split("/", var.flux_github_repository)[1]} --branch=${var.flux_github_branch} --path=${var.flux_github_path} --token=${var.flux_github_token}" : "echo 'Flux bootstrap skipped'",
      
      # Install MetalLB (if enabled)
      var.enable_metallb ? "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v${var.metallb_version}/config/manifests/metallb-native.yaml" : "echo 'MetalLB installation skipped'",
      
      # Install NGINX Ingress Controller (if enabled)
      var.enable_ingress_nginx ? "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${var.ingress_nginx_version}/deploy/static/provider/cloud/deploy.yaml" : "echo 'NGINX Ingress installation skipped'"
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Copy kubeconfig from master node
      scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.vm_username}@${data.external.master_ips[0].result.ip}:~/.kube/config ./kubeconfig
      
      # Update kubeconfig with correct server IP
      sed -i "s/127.0.0.1:6443/${data.external.master_ips[0].result.ip}:6443/g" ./kubeconfig
      
      echo "Kubeconfig saved to ./kubeconfig"
    EOT
  }
}

# Configure load balancers after cluster is ready
resource "null_resource" "configure_load_balancers" {
  depends_on = [null_resource.kubeadm_init]

  connection {
    type        = "ssh"
    host        = data.external.master_ips[0].result.ip
    user        = var.vm_username
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # Wait for MetalLB to be ready
      var.enable_metallb ? "kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s" : "echo 'MetalLB not enabled'",
      # Configure MetalLB IP pool
      var.enable_metallb && var.metallb_ip_range != "" ? "kubectl apply -f - <<EOF\napiVersion: metallb.io/v1beta1\nkind: IPAddressPool\nmetadata:\n  name: first-pool\n  namespace: metallb-system\nspec:\n  addresses:\n  - ${var.metallb_ip_range}\n---\napiVersion: metallb.io/v1beta1\nkind: L2Advertisement\nmetadata:\n  name: example\n  namespace: metallb-system\nspec:\n  ipAddressPools:\n  - first-pool\nEOF" : "echo 'MetalLB IP pool configuration skipped'",
      # Configure KubeVIP for API server
      var.enable_kubevip && var.api_server_vip != "" ? "kubectl apply -f - <<EOF\napiVersion: v1\nkind: Service\nmetadata:\n  name: kubevip\n  namespace: kube-system\nspec:\n  type: LoadBalancer\n  loadBalancerIP: ${var.api_server_vip}\n  ports:\n  - port: 6443\n    targetPort: 6443\n    protocol: TCP\n    name: https\n  selector:\n    app: kubevip\nEOF" : "echo 'KubeVIP configuration skipped'"
    ]
  }
}

# Join worker nodes
resource "null_resource" "kubeadm_join_workers" {
  count = var.worker_count
  depends_on = [null_resource.kubeadm_init]

  connection {
    type        = "ssh"
    host        = "worker-${count.index + 1}-ip"  # This would need to be dynamically determined
    user        = var.vm_username
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join ${data.external.master_ips[0].result.ip}:6443 --token $(kubectl -n kube-system get secret $(kubectl -n kube-system get sa kubeadm-bootstrap-token -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
    ]
  }
}
