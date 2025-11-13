# HTTP-Echo Project - Quick Reference

## 🎯 What This Project Does

A **GitOps-based Kubernetes deployment** that automatically:
1. Provisions a Hetzner Cloud server with k3s
2. Installs ArgoCD for continuous deployment
3. Deploys an http-echo web application
4. Exposes it via nginx-ingress

## 📁 Directory Structure

```
http-echo/
├── infra/terraform/     → Infrastructure provisioning (Terraform)
├── helm/http-echo/     → Application packaging (Helm charts)
└── argocd/             → GitOps configuration (ArgoCD apps)
```

## 🔄 How It Works

```
Terraform → Creates Server → Installs k3s/Helm/ArgoCD
    ↓
ArgoCD → Watches Git Repo → Detects Changes
    ↓
Helm → Renders Templates → Generates K8s Manifests
    ↓
Kubernetes → Deploys Pods → Exposes via Ingress
```

## 🛠️ Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **Terraform** | Infrastructure provisioning | `infra/terraform/` |
| **k3s** | Lightweight Kubernetes | Installed via cloud-init |
| **Helm** | Application packaging | `helm/http-echo/` |
| **ArgoCD** | GitOps engine | `argocd/*.yaml` |
| **nginx-ingress** | External access | ArgoCD app |
| **http-echo** | Demo application | Helm chart |

## 📝 Key Files

- `infra/terraform/hetzner.tf` - Server provisioning with cloud-init
- `helm/http-echo/values.yaml` - App configuration
- `argocd/http-echo-application.yaml` - GitOps app definition
- `argocd/ingress-nginx-application.yaml` - Ingress controller

## 🚀 Deployment Flow

1. **Infrastructure:** `terraform apply` → Creates Hetzner server
2. **Bootstrap:** Cloud-init installs k3s, Helm, ArgoCD
3. **GitOps:** ArgoCD syncs from Git repository
4. **Application:** Helm renders and deploys http-echo
5. **Access:** Visit `echo.<IP>.sslip.io`

## 🔑 Key Concepts

- **GitOps:** Git repository is source of truth
- **Infrastructure as Code:** Terraform defines infrastructure
- **Declarative:** Describe desired state, tools make it happen
- **Automated Sync:** Changes in Git auto-deploy to cluster
- **Self-healing:** ArgoCD reverts manual cluster changes

## 📊 Architecture Levels

- **Beginner:** Understands what each tool does
- **Intermediate:** Understands how components interact
- **Advanced:** Understands implementation details and optimizations

See `PROJECT_DOCUMENTATION.md` for detailed explanations at all three levels.

