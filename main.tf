terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 3.0"
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

# Generate cloud-init configuration
locals {
  cloud_init_config = templatefile("${path.module}/templates/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
    vm_username    = var.vm_username
    vm_password    = var.vm_password
    kubernetes_version = var.kubernetes_version
    container_runtime = var.container_runtime
    pod_cidr = var.pod_cidr
    service_cidr = var.service_cidr
    cluster_dns = var.cluster_dns
    enable_flux = var.enable_flux
    flux_version = var.flux_version
    enable_kubevip = var.enable_kubevip
    kubevip_version = var.kubevip_version
  })
}

# Upload cloud-init configuration to Proxmox
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.proxmox_datastore
  node_name    = var.proxmox_node_name

  source_raw {
    data = local.cloud_init_config
    file_name = "kubernetes-cloud-init.yaml"
  }
}

# Data source for Proxmox node
data "proxmox_virtual_environment_nodes" "available" {}

# Create master nodes
resource "proxmox_virtual_environment_vm" "master_nodes" {
  count = var.master_count

  name        = "${var.cluster_name}-master-${count.index + 1}"
  description = "Kubernetes master node ${count.index + 1}"
  tags        = ["kubernetes", "master", var.cluster_name]

  node_name = var.proxmox_node_name

  agent {
    enabled = true
  }

  cpu {
    cores = var.master_cpu_cores
  }

  memory {
    dedicated = var.master_memory
  }

  disk {
    datastore_id = var.proxmox_datastore
    file_id      = var.proxmox_template
    interface    = "scsi0"
    size         = var.master_disk_size
  }

  network_device {
    bridge = var.proxmox_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.proxmox_datastore
    interface    = "ide2"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.ssh_public_key]
      password = var.vm_password
      username = var.vm_username
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
    ]
  }
}

# Create worker nodes
resource "proxmox_virtual_environment_vm" "worker_nodes" {
  count = var.worker_count

  name        = "${var.cluster_name}-worker-${count.index + 1}"
  description = "Kubernetes worker node ${count.index + 1}"
  tags        = ["kubernetes", "worker", var.cluster_name]

  node_name = var.proxmox_node_name

  agent {
    enabled = true
  }

  cpu {
    cores = var.worker_cpu_cores
  }

  memory {
    dedicated = var.worker_memory
  }

  disk {
    datastore_id = var.proxmox_datastore
    file_id      = var.proxmox_template
    interface    = "scsi0"
    size         = var.worker_disk_size
  }

  network_device {
    bridge = var.proxmox_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.proxmox_datastore
    interface    = "ide2"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      keys     = [var.ssh_public_key]
      password = var.vm_password
      username = var.vm_username
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  lifecycle {
    ignore_changes = [
      network_device[0].mac_address,
    ]
  }
}

# Wait for VMs to be ready
resource "time_sleep" "wait_for_vms" {
  depends_on = [
    proxmox_virtual_environment_vm.master_nodes,
    proxmox_virtual_environment_vm.worker_nodes
  ]

  create_duration = "60s"
}

# Get master node IP addresses from Proxmox
data "external" "master_ips" {
  count = var.master_count
  depends_on = [time_sleep.wait_for_vms]
  
  program = ["bash", "-c", <<-EOT
    # Get the IP address of the master node from Proxmox
    VM_ID=${proxmox_virtual_environment_vm.master_nodes[count.index].vm_id}
    NODE_NAME="${var.proxmox_node_name}"
    
    # Use Proxmox API to get VM IP
    IP=$(curl -s -k -H "Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token_secret}" \
      "${var.proxmox_api_url}/nodes/$NODE_NAME/qemu/$VM_ID/agent/network-get-interfaces" | \
      jq -r '.data.result[] | select(.name=="eth0") | .["ip-addresses"][] | select(.["ip-address-type"]=="ipv4") | .["ip-address"]' | head -1)
    
    if [ -z "$IP" ]; then
      echo '{"ip": "unknown"}'
    else
      echo "{\"ip\": \"$IP\"}"
    fi
  EOT
  ]
}

# Initialize Kubernetes cluster on first master node
resource "null_resource" "kubeadm_init" {
  count = 1
  depends_on = [time_sleep.wait_for_vms]

  connection {
    type        = "ssh"
    host        = data.external.master_ips[0].result.ip
    user        = var.vm_username
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init --pod-network-cidr=${var.pod_cidr} --service-cidr=${var.service_cidr} --kubernetes-version=${var.kubernetes_version}",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml",
      # Install Flux if enabled
      var.enable_flux ? "flux install --version=${var.flux_version}" : "echo 'Flux installation skipped'",
      # Bootstrap Flux with GitHub repository if configured
      var.enable_flux && var.flux_github_repository != "" ? "flux bootstrap github --owner=${split("/", var.flux_github_repository)[0]} --repository=${split("/", var.flux_github_repository)[1]} --branch=${var.flux_github_branch} --path=${var.flux_github_path} --token-auth" : "echo 'Flux GitHub bootstrap skipped'",
      # Install MetalLB if enabled
      var.enable_metallb ? "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml" : "echo 'MetalLB installation skipped'",
      # Install NGINX Ingress Controller if enabled
      var.enable_ingress_nginx ? "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${var.ingress_nginx_version}/deploy/static/provider/cloud/deploy.yaml" : "echo 'NGINX Ingress installation skipped'"
    ]
  }

  # Extract kubeconfig for local use
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for master node to be ready..."
      sleep 30
      echo "Extracting kubeconfig..."
      
      # Get the master node IP from Terraform data source
      MASTER_IP="${data.external.master_ips[0].result.ip}"
      echo "Master node IP: $MASTER_IP"
      
      if [ "$MASTER_IP" = "unknown" ]; then
        echo "Warning: Could not determine master node IP. You may need to manually configure kubeconfig."
        exit 0
      fi
      
      # Create kubeconfig directory
      mkdir -p ./kubeconfig
      
      # Copy kubeconfig from master node
      scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.vm_username}@$MASTER_IP:~/.kube/config ./kubeconfig/kubeconfig-${var.cluster_name}
      
      # Update kubeconfig with correct server IP
      sed -i "s/127.0.0.1:6443/$MASTER_IP:6443/g" ./kubeconfig/kubeconfig-${var.cluster_name}
      
      echo "Kubeconfig saved to ./kubeconfig/kubeconfig-${var.cluster_name}"
      echo "To use this kubeconfig:"
      echo "export KUBECONFIG=./kubeconfig/kubeconfig-${var.cluster_name}"
      echo "kubectl get nodes"
    EOT
    working_dir = path.module
  }
}

# Configure MetalLB and KubeVIP after cluster is ready
resource "null_resource" "configure_load_balancers" {
  count = var.enable_metallb || var.enable_kubevip ? 1 : 0
  depends_on = [null_resource.kubeadm_init]

  connection {
    type        = "ssh"
    host        = data.external.master_ips[0].result.ip
    user        = var.vm_username
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # Wait for MetalLB to be ready
      var.enable_metallb ? "kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s" : "echo 'MetalLB not enabled'",
      # Configure MetalLB IP pool
      var.enable_metallb && var.metallb_ip_range != "" ? <<-EOT
        cat <<EOF | kubectl apply -f -
        apiVersion: metallb.io/v1beta1
        kind: IPAddressPool
        metadata:
          name: first-pool
          namespace: metallb-system
        spec:
          addresses:
          - ${var.metallb_ip_range}
        ---
        apiVersion: metallb.io/v1beta1
        kind: L2Advertisement
        metadata:
          name: example
          namespace: metallb-system
        spec:
          ipAddressPools:
          - first-pool
        EOF
      EOT : "echo 'MetalLB IP pool configuration skipped'",
      # Configure KubeVIP for API server
      var.enable_kubevip && var.api_server_vip != "" ? <<-EOT
        cat <<EOF | kubectl apply -f -
        apiVersion: v1
        kind: Service
        metadata:
          name: kubevip
          namespace: kube-system
        spec:
          type: LoadBalancer
          loadBalancerIP: ${var.api_server_vip}
          ports:
          - port: 6443
            targetPort: 6443
            protocol: TCP
            name: https
          selector:
            app: kubevip
        EOF
      EOT : "echo 'KubeVIP configuration skipped'"
    ]
  }
}

# Join additional master nodes (if any)
resource "null_resource" "kubeadm_join_masters" {
  count = var.master_count > 1 ? var.master_count - 1 : 0
  depends_on = [null_resource.kubeadm_init]

  connection {
    type        = "ssh"
    host        = data.external.master_ips[count.index + 1].result.ip
    user        = var.vm_username
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join ${data.external.master_ips[0].result.ip}:6443 --token $(kubectl -n kube-system get secret $(kubectl -n kube-system get sa kubeadm-bootstrap-token -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //') --control-plane"
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
    private_key = file("~/.ssh/id_rsa")
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join ${data.external.master_ips[0].result.ip}:6443 --token $(kubectl -n kube-system get secret $(kubectl -n kube-system get sa kubeadm-bootstrap-token -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
    ]
  }
}