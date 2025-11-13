# HTTP-Echo Project - Complete Documentation

## 📋 Project Overview

This project demonstrates a **complete GitOps-based Kubernetes deployment pipeline** that automatically provisions cloud infrastructure, sets up a Kubernetes cluster, and deploys a simple web application using modern DevOps practices.

**What it does:** Deploys a simple HTTP echo server (`http-echo`) that responds with a greeting message when accessed via a web browser. While the application itself is simple, the infrastructure and deployment methodology showcase enterprise-grade practices.

---

## 🏗️ Architecture & Structure

```
http-echo/
├── infra/terraform/          # Infrastructure as Code (IaC)
│   ├── hetzner.tf           # Cloud server provisioning
│   ├── main.tf              # Kubernetes resources (commented out)
│   ├── variables.tf         # Configuration variables
│   └── providers.tf         # Terraform providers
│
├── helm/http-echo/          # Application packaging
│   ├── Chart.yaml           # Helm chart metadata
│   ├── values.yaml          # Application configuration
│   └── templates/           # Kubernetes manifests
│       ├── deployment.yaml  # Pod specifications
│       ├── service.yaml     # Network service
│       └── ingress.yaml     # External access
│
└── argocd/                  # GitOps configuration
    ├── namespaces.yaml      # Kubernetes namespaces
    ├── argocd-application.yaml      # ArgoCD self-deployment
    ├── ingress-nginx-application.yaml  # Ingress controller
    └── http-echo-application.yaml     # Main app deployment
```

### Architecture Flow

```
┌─────────────────┐
│  Terraform      │  →  Provisions Hetzner Cloud server
│  (Infrastructure)│     Installs k3s (lightweight K8s)
└────────┬────────┘     Installs Helm & ArgoCD
         │
         ▼
┌─────────────────┐
│  ArgoCD         │  →  Monitors Git repository
│  (GitOps Engine)│     Automatically syncs changes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Helm Charts    │  →  Packages application
│  (Templates)    │     Generates K8s manifests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Kubernetes     │  →  Runs http-echo containers
│  (Orchestration)│     Exposes via Ingress
└─────────────────┘
```

---

## 📚 Detailed Explanations by Level

---

## 🟢 BEGINNER LEVEL

### What is this project?

Imagine you want to run a simple website that says "Hello" when someone visits it. This project automates the entire process:

1. **Creates a computer in the cloud** (like renting a server)
2. **Installs Kubernetes** (a system to run applications)
3. **Deploys your website** automatically
4. **Keeps it updated** whenever you make changes

### Key Concepts Explained Simply

#### 1. **Terraform** (`infra/terraform/`)
- **What it is:** A tool that writes code to create servers and infrastructure
- **What it does here:** 
  - Creates a virtual server on Hetzner Cloud (a cloud provider)
  - Installs k3s (a lightweight version of Kubernetes)
  - Sets up Helm and ArgoCD automatically
- **Why use it:** Instead of clicking buttons in a web interface, you write code that can be repeated and version-controlled

**Example from `hetzner.tf`:**
```terraform
resource "hcloud_server" "k3s" {
  name        = "k3s-server"
  server_type = "cx33"  # Server size
  location    = "nbg1"  # Data center location
}
```
This creates a server named "k3s-server" with specific size and location.

#### 2. **Helm** (`helm/http-echo/`)
- **What it is:** A package manager for Kubernetes (like npm for Node.js or pip for Python)
- **What it does here:**
  - Packages the http-echo application
  - Defines how many copies to run (2 replicas)
  - Configures the application settings
- **Why use it:** Makes it easy to deploy and update applications

**Example from `values.yaml`:**
```yaml
replicaCount: 2  # Run 2 copies of the app
args:
  - "-text=Hello from ArgoCD + Helm + Terraform 👋👋👋"
```
This tells Kubernetes to run 2 copies of the app, and each will display that greeting message.

#### 3. **ArgoCD** (`argocd/`)
- **What it is:** A tool that watches your code repository and automatically deploys changes
- **What it does here:**
  - Watches the GitHub repository
  - When you push code changes, it automatically updates the running application
  - Keeps the cluster in sync with your code
- **Why use it:** "GitOps" - your Git repository is the source of truth. Make a change, push it, and it deploys automatically.

**Example from `http-echo-application.yaml`:**
```yaml
source:
  repoURL: https://github.com/mohamedtalat90/http-echo.git
  path: helm/http-echo
```
This tells ArgoCD: "Watch this GitHub repo, and whenever the `helm/http-echo` folder changes, update the application."

#### 4. **Kubernetes Components**

**Deployment** (`templates/deployment.yaml`):
- Defines what container image to run
- How many copies (replicas)
- Resource limits (CPU, memory)

**Service** (`templates/service.yaml`):
- Creates a stable network address for the pods
- Like a phone number that always works, even if pods restart

**Ingress** (`templates/ingress.yaml`):
- Makes the application accessible from the internet
- Routes traffic from a domain name to the service

### How It All Works Together (Beginner)

1. **You run Terraform** → Creates a cloud server with Kubernetes
2. **ArgoCD is installed** → Starts watching your GitHub repository
3. **ArgoCD reads the Helm chart** → Generates Kubernetes configuration
4. **Kubernetes runs the containers** → Your http-echo app is live
5. **You make a change and push to Git** → ArgoCD automatically updates the app

---

## 🟡 INTERMEDIATE LEVEL

### Infrastructure Layer (Terraform)

#### Hetzner Cloud Provisioning (`hetzner.tf`)

The Terraform configuration uses **cloud-init** to bootstrap the server:

```terraform
user_data = local.cloud_init
```

**Cloud-init script does:**
1. **Installs k3s** (lightweight Kubernetes):
   - Disables Traefik (k3s's default ingress) since we use nginx-ingress
   - Makes kubeconfig readable (`--write-kubeconfig-mode 644`)
   
2. **Waits for cluster readiness:**
   - Polls for kubeconfig file existence
   - Waits for node to be in "Ready" state
   - Uses retry logic (60 attempts with delays)

3. **Installs Helm:**
   - Downloads and installs Helm 3
   - Required for ArgoCD installation

4. **Installs ArgoCD via Helm:**
   - Adds ArgoCD Helm repository
   - Creates `argocd` namespace
   - Installs with `--wait` flag (blocks until ready)
   - Uses idempotent check (only installs if not present)

**Key Design Decisions:**
- **Idempotent bootstrap:** Uses a marker file (`/var/lib/bootstrap_k3s_helm.done`) to prevent re-running
- **Systemd service:** Runs as a oneshot service that executes once
- **Lifecycle ignore:** `ignore_changes = [user_data]` prevents Terraform from re-running cloud-init on every apply

#### Terraform State Management
- State files track what infrastructure exists
- Backups are created automatically
- Variables are defined in `variables.tf` and values in `terraform.tfvars`

### Application Layer (Helm)

#### Helm Chart Structure

**Chart.yaml:**
```yaml
name: http-echo
version: 0.1.0
appVersion: "0.2.3"  # Version of http-echo container
```

**values.yaml - Configuration:**
- **Replica count:** 2 (for high availability)
- **Image:** `hashicorp/http-echo:0.2.3` (official HashiCorp image)
- **Args:** Custom text and listen port
- **Resources:** CPU/memory requests and limits
- **Ingress:** Domain configuration using sslip.io (dynamic DNS)

**Templates - Kubernetes Manifests:**

1. **deployment.yaml:**
   - Uses Helm templating (`{{ .Values.replicaCount }}`)
   - Defines health checks:
     - **Readiness probe:** Checks if pod can accept traffic (starts after 3s, checks every 5s)
     - **Liveness probe:** Checks if pod is alive (starts after 10s, checks every 10s)
   - Resource limits prevent resource exhaustion

2. **service.yaml:**
   - ClusterIP type (internal only)
   - Port mapping: external port 80 → container port 5678
   - Selector matches pods with label `app: http-echo`

3. **ingress.yaml:**
   - Conditional rendering (`{{- if .Values.ingress.enabled }}`)
   - Uses nginx ingress class
   - Routes traffic from domain to service
   - Supports TLS configuration (currently empty)

### GitOps Layer (ArgoCD)

#### Application Definitions

ArgoCD uses **Application CRDs** (Custom Resource Definitions) to define what to deploy:

1. **argocd-application.yaml:**
   - Self-deployment of ArgoCD
   - Sources from Helm chart repository
   - Configures ingress with domain `argocd.116.203.226.140.sslip.io`
   - Sets `server.insecure: true` (for demo purposes)

2. **ingress-nginx-application.yaml:**
   - Deploys nginx-ingress controller
   - Uses `hostPort` mode (exposes ports 80/443 directly on node)
   - Required for bare-metal/cloud VPS (no cloud load balancer)

3. **http-echo-application.yaml:**
   - Main application deployment
   - Sources from Git repository
   - Points to `helm/http-echo` path
   - Uses automated sync with self-healing

#### Sync Policies

```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Revert manual changes
  syncOptions:
    - CreateNamespace=true  # Auto-create namespace
```

**What this means:**
- **Automated sync:** No manual approval needed
- **Prune:** If you delete something in Git, ArgoCD deletes it from cluster
- **Self-heal:** If someone manually changes the cluster, ArgoCD reverts it to match Git
- **CreateNamespace:** Automatically creates the namespace if it doesn't exist

### Network Architecture

```
Internet
   │
   ▼
[Ingress Controller (nginx)]
   │ (hostPort 80/443)
   ▼
[Ingress Resource]
   │ (routes by hostname)
   ▼
[Service (ClusterIP)]
   │ (load balances)
   ▼
[Pods (2 replicas)]
   │
   ▼
http-echo containers
```

**Traffic Flow:**
1. User visits `echo.116.203.226.140.sslip.io`
2. DNS resolves to server IP
3. Ingress controller (nginx) receives request on port 80
4. Ingress resource matches hostname and routes to `http-echo` service
5. Service load balances between 2 pod replicas
6. Pod responds with greeting message

### Domain Configuration

The project uses **sslip.io** for dynamic DNS:
- Format: `<IP>.sslip.io`
- Example: `116.203.226.140.sslip.io`
- Automatically resolves to the IP address
- No manual DNS configuration needed
- Perfect for demos and testing

---

## 🔴 ADVANCED LEVEL

### Infrastructure Deep Dive

#### Cloud-Init Bootstrap Strategy

The bootstrap script uses a **multi-stage approach** with proper error handling:

```bash
# Stage 1: k3s installation
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh -
fi
```

**Why disable Traefik?**
- k3s includes Traefik by default
- We use nginx-ingress for consistency with standard Kubernetes
- Prevents port conflicts and resource waste

**Why `--write-kubeconfig-mode 644`?**
- Default mode is 600 (owner-only)
- 644 allows group/other read access
- Needed for cloud-init scripts and remote access

#### Idempotency Pattern

```bash
if ! helm list -n argocd 2>/dev/null | grep -q argocd; then
  # Install ArgoCD
fi
```

**Idempotency checks:**
1. **Command existence:** `command -v k3s` / `command -v helm`
2. **Helm release:** `helm list | grep -q argocd`
3. **Marker file:** `/var/lib/bootstrap_k3s_helm.done`

**Why multiple checks?**
- Command existence: Fast check, but doesn't verify installation success
- Helm release: Verifies actual deployment state
- Marker file: Survives reboots, prevents re-execution

#### Systemd Service Design

```systemd
[Service]
Type=oneshot
ExecStart=/usr/local/bin/bootstrap_k3s_helm.sh
RemainAfterExit=yes
```

**Type=oneshot:**
- Runs once, doesn't restart
- Perfect for bootstrap scripts
- Systemd waits for completion

**RemainAfterExit=yes:**
- Keeps service in "active" state after completion
- Prevents systemd from considering it failed
- Allows dependency tracking

**ConditionPathExists:**
```systemd
ConditionPathExists=!/var/lib/bootstrap_k3s_helm.done
```
- Only runs if marker file doesn't exist
- Prevents re-execution on reboot

### Helm Chart Advanced Features

#### Template Functions

**Range loops:**
```yaml
{{- range .Values.args }}
  - {{ . | quote }}
{{- end }}
```
- Iterates over array values
- `| quote` escapes special characters
- Generates YAML list items

**Conditional rendering:**
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
{{- end }}
```
- Only includes resource if enabled
- Reduces unnecessary Kubernetes objects
- Follows Helm best practices

**YAML indentation:**
```yaml
{{- toYaml .Values.resources | nindent 12 }}
```
- Converts Go struct to YAML
- `nindent 12` adds 12 spaces of indentation
- Maintains proper YAML structure

#### Health Check Strategy

**Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 3
  periodSeconds: 5
```

**Liveness Probe:**
```yaml
livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
```

**Why different timings?**
- **Readiness:** Fast checks (3s initial, 5s period) - want to serve traffic ASAP
- **Liveness:** Slower checks (10s initial, 10s period) - avoid killing pods during startup
- **Different purposes:**
  - Readiness: "Can I accept traffic?" (removes from Service endpoints if fails)
  - Liveness: "Am I alive?" (restarts pod if fails)

**Probe failure behavior:**
- Readiness failure → Pod removed from Service, but not restarted
- Liveness failure → Pod is killed and recreated

### ArgoCD Advanced Concepts

#### Application Source Types

**Helm Chart from Repository:**
```yaml
source:
  repoURL: https://argoproj.github.io/argo-helm
  chart: argo-cd
  targetRevision: 7.7.10
  helm:
    values: |
      global:
        domain: argocd.116.203.226.140.sslip.io
```

**Git Repository with Helm:**
```yaml
source:
  repoURL: https://github.com/mohamedtalat90/http-echo.git
  targetRevision: main
  path: helm/http-echo
  helm:
    valueFiles:
      - values.yaml
```

**Differences:**
- **Chart repo:** Pre-packaged charts, versioned by chart version
- **Git repo:** Source code, versioned by Git commit/tag
- **Helm values:** Inline YAML vs. value files

#### Sync Strategies

**Automated Sync:**
```yaml
automated:
  prune: true
  selfHeal: true
```

**Prune behavior:**
- Compares desired state (Git) vs. actual state (cluster)
- Deletes resources that exist in cluster but not in Git
- **Dangerous but powerful:** Ensures Git is source of truth

**Self-heal behavior:**
- Detects manual changes to cluster
- Automatically reverts to Git state
- **Prevents drift:** Cluster always matches Git

**Sync options:**
- `CreateNamespace=true`: Auto-creates namespace
- `PrunePropagationPolicy`: How to handle dependent resources
- `PruneLast`: Delete resources in specific order

#### Ingress Controller Configuration

**hostPort Mode:**
```yaml
controller:
  hostPort:
    enabled: true
  service:
    type: ClusterIP
```

**Why hostPort?**
- **Bare-metal/VPS:** No cloud load balancer
- **Direct access:** Ports 80/443 bound directly to node IP
- **No NodePort needed:** Simpler networking
- **Single node:** Works perfectly for k3s single-node setup

**Alternative approaches:**
- **NodePort:** Exposes service on high ports (30000+)
- **LoadBalancer:** Requires cloud provider integration
- **hostPort:** Direct binding (used here)

### Kubernetes Resource Management

#### Resource Quotas

```yaml
resources:
  requests:
    cpu: 10m      # 0.01 CPU cores
    memory: 32Mi  # 32 megabytes
  limits:
    cpu: 100m     # 0.1 CPU cores
    memory: 64Mi  # 64 megabytes
```

**Requests vs. Limits:**
- **Requests:** Guaranteed resources (scheduler uses for placement)
- **Limits:** Maximum resources (container killed if exceeded)

**Why small resources?**
- http-echo is lightweight (just echoes text)
- Allows many replicas on small nodes
- Demonstrates resource efficiency

**CPU units:**
- `10m` = 10 millicores = 0.01 CPU
- `100m` = 100 millicores = 0.1 CPU
- Kubernetes uses millicores for precision

#### Replica Strategy

```yaml
replicaCount: 2
```

**Why 2 replicas?**
- **High availability:** If one pod fails, other serves traffic
- **Load distribution:** Service load balances between replicas
- **Rolling updates:** Zero-downtime deployments

**Pod Disruption Budget (not shown but recommended):**
- Could add PDB to ensure at least 1 pod always running
- Prevents both pods from being terminated simultaneously

### GitOps Workflow

#### Complete Deployment Flow

```
Developer
   │
   ├─> Edit values.yaml (change replicaCount: 2 → 3)
   │
   ├─> git commit -m "Scale to 3 replicas"
   │
   ├─> git push origin main
   │
   ▼
GitHub Repository
   │
   ▼
ArgoCD (polls every 3 minutes by default)
   │
   ├─> Detects change in helm/http-echo/values.yaml
   │
   ├─> Renders Helm chart with new values
   │
   ├─> Compares desired state vs. cluster state
   │
   ├─> Generates diff: +1 replica needed
   │
   ▼
Kubernetes API
   │
   ├─> Updates Deployment spec.replicas: 2 → 3
   │
   ├─> Deployment controller creates new ReplicaSet
   │
   ├─> Scheduler places new pod on node
   │
   ├─> Kubelet starts container
   │
   ├─> Readiness probe passes
   │
   ▼
Service endpoints updated
   │
   ▼
Traffic now load-balanced across 3 pods
```

#### ArgoCD Sync Phases

1. **Comparison Phase:**
   - Fetches manifests from source
   - Renders Helm templates
   - Compares with live cluster state
   - Generates diff

2. **Sync Phase:**
   - Applies changes to cluster
   - Waits for resources to be ready
   - Validates health status

3. **Health Check Phase:**
   - Monitors resource health
   - Updates Application status
   - Triggers self-healing if needed

### Security Considerations

#### Current Security Posture

**Insecure configurations (for demo):**
- `server.insecure: true` in ArgoCD
- No TLS on ingress
- No RBAC restrictions shown
- No network policies

**Production improvements needed:**
1. **TLS/SSL:**
   - Install cert-manager
   - Use Let's Encrypt certificates
   - Enable HTTPS on all ingress

2. **Authentication:**
   - Configure ArgoCD SSO (OIDC/SAML)
   - Enable RBAC policies
   - Use service accounts with minimal permissions

3. **Network Security:**
   - Implement NetworkPolicies
   - Restrict pod-to-pod communication
   - Use private container registries

4. **Secrets Management:**
   - Use Sealed Secrets or External Secrets Operator
   - Encrypt secrets at rest
   - Rotate credentials regularly

### Monitoring & Observability

#### What's Missing (Advanced Topics)

**Metrics:**
- Prometheus for metrics collection
- Grafana for visualization
- ArgoCD metrics endpoint

**Logging:**
- Centralized logging (Loki, ELK stack)
- Log aggregation from all pods
- Log retention policies

**Tracing:**
- Distributed tracing (Jaeger, Zipkin)
- Request flow visualization
- Performance bottleneck identification

**Alerting:**
- AlertManager for notifications
- Slack/email integration
- PagerDuty for critical alerts

### Scalability Considerations

#### Current Limitations

**Single-node k3s:**
- No high availability
- Single point of failure
- Limited to single server resources

**Scaling options:**
1. **Multi-node k3s:**
   - Add worker nodes
   - Enable HA control plane
   - Distribute workloads

2. **Managed Kubernetes:**
   - EKS, GKE, AKS
   - Auto-scaling node groups
   - Managed control plane

3. **Horizontal Pod Autoscaling:**
   - Scale pods based on CPU/memory
   - Custom metrics support
   - Predictive scaling

### Advanced Terraform Patterns

#### State Management

**Remote State (not shown but recommended):**
```terraform
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "http-echo/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Benefits:**
- Shared state for team collaboration
- State locking prevents conflicts
- State versioning and history

#### Workspaces

**Environment separation:**
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

**Use cases:**
- Separate infrastructure per environment
- Different variable values
- Isolated state files

#### Modules

**Reusable components:**
```terraform
module "k3s_cluster" {
  source = "./modules/k3s"
  
  server_type = var.server_type
  location    = var.location
}
```

**Benefits:**
- Code reusability
- Encapsulation
- Versioning

---

## 🎯 Summary

This project demonstrates a **complete GitOps pipeline** from infrastructure to application:

1. **Terraform** provisions cloud infrastructure and bootstraps Kubernetes
2. **Helm** packages the application with configurable values
3. **ArgoCD** continuously syncs Git state to the cluster
4. **Kubernetes** orchestrates container workloads
5. **Ingress** exposes applications to the internet

**Key Technologies:**
- Infrastructure: Terraform, Hetzner Cloud, k3s
- Packaging: Helm
- GitOps: ArgoCD
- Orchestration: Kubernetes
- Networking: nginx-ingress

**Best Practices Demonstrated:**
- Infrastructure as Code
- GitOps methodology
- Declarative configuration
- Automated deployments
- Idempotent operations
- Health checks and probes
- Resource management

This is a **production-ready foundation** that can be extended with monitoring, security, and scaling features for enterprise use.

