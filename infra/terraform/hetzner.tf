resource "hcloud_ssh_key" "local" {
  name       = "terraform-key"
  public_key = file(var.ssh_public_key_path)
}

# Idempotent cloud-init: install k3s once, then install Helm and ArgoCD after k8s is ready
locals {
  cloud_init = <<-EOT
    #cloud-config
    write_files:
      - path: /usr/local/bin/bootstrap_k3s_helm.sh
        permissions: '0755'
        owner: root:root
        content: |
          #!/usr/bin/env bash
          set -euo pipefail

          if ! command -v k3s >/dev/null 2>&1; then
            echo "Installing k3s..."
            curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh -
          else
            echo "k3s already installed, skipping."
          fi

          # Wait for kubeconfig and node readiness
          export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
          echo "Waiting for k3s kubeconfig..."
          for i in {1..60}; do
            [[ -f "$KUBECONFIG" ]] && break
            sleep 2
          done
          if [[ ! -f "$KUBECONFIG" ]]; then
            echo "kubeconfig not found after waiting" >&2
            exit 1
          fi

          echo "Waiting for node to be Ready..."
          for i in {1..60}; do
            if kubectl get nodes 1>/dev/null 2>&1; then
              if kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q True; then
                break
              fi
            fi
            sleep 5
          done

          if ! command -v helm >/dev/null 2>&1; then
            echo "Installing Helm..."
            curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
          else
            echo "Helm already installed, skipping."
          fi

          # Install ArgoCD using Helm
          echo "Setting up ArgoCD..."
          if ! helm list -n argocd 2>/dev/null | grep -q argocd; then
            echo "Installing ArgoCD..."
            helm repo add argo https://argoproj.github.io/argo-helm
            helm repo update
            kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
            helm install argocd argo/argo-cd \
              --namespace argocd \
              --wait \
              --timeout 10m
            echo "ArgoCD installed successfully."
          else
            echo "ArgoCD already installed, skipping."
          fi

          touch /var/lib/bootstrap_k3s_helm.done

      - path: /etc/systemd/system/bootstrap-k3s-helm.service
        permissions: '0644'
        owner: root:root
        content: |
          [Unit]
          Description=One-time bootstrap for k3s, Helm, and ArgoCD
          Wants=network-online.target
          After=network-online.target
          ConditionPathExists=!/var/lib/bootstrap_k3s_helm.done

          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/bootstrap_k3s_helm.sh
          RemainAfterExit=yes

          [Install]
          WantedBy=multi-user.target

    runcmd:
      - systemctl daemon-reload
      - systemctl enable --now bootstrap-k3s-helm.service
  EOT
}

resource "hcloud_server" "k3s" {
  name        = var.hostname
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.local.name]
  user_data   = local.cloud_init

  # open basic ports with Hetzner Cloud firewall (optional)

  lifecycle {
    ignore_changes = [user_data]
  }
}

# After server boots, you’ll pull kubeconfig manually once (documented below).
output "server_ipv4" {
  value = hcloud_server.k3s.ipv4_address
}



