# 1) Namespaces
resource "kubernetes_namespace" "argocd" {
  metadata { name = var.argocd_namespace }
}

resource "kubernetes_namespace" "app" {
  metadata { name = var.app_namespace }
}

# 2) Install ingress-nginx (bare-metal friendly)
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"
  namespace  = "ingress-nginx"
  create_namespace = true

  # HostPort 80/443 so you can hit http(s)://<localhost> without a cloud LB
  values = [
    yamlencode({
      controller = {
        ingressClass = "nginx"
        ingressClassResource = { name = "nginx" }
        hostPort = { enabled = true }
        service  = { type = "ClusterIP" }  # we don't need a Service LB/NodePort since we use hostPort
      }
    })
  ]
}

# 3) Install Argo CD
resource "helm_release" "argocd" {
  depends_on = [helm_release.ingress_nginx]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.10"
  namespace  = var.argocd_namespace

  set {
    name  = "crds.install"
    value = true
  }

  wait    = true
  timeout = 600
  atomic  = true

  values = [
    yamlencode({
      server = {
        service = { type = "ClusterIP" }
        ingress = {
          enabled           = true
          ingressClassName  = "nginx"
          # Expose the UI at https://argocd.local
          hosts = [{
            host  = "argocd.local"
            paths = [{ path = "/", pathType = "Prefix" }]
          }]
          tls = [] # keep http for demo; you can add TLS later
        }
      }
      configs = {
        params = { "server.insecure" = true } # ok for demo
      }
    })
  ]
}

# 4) Wait for Argo CD CRDs to be established after Helm install
resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "45s"
}

# 5) Argo CD Application for http-echo
resource "kubernetes_manifest" "argocd_app_http_echo" {
  depends_on = [time_sleep.wait_for_argocd_crds]

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata   = {
      name      = "http-echo"
      namespace = var.argocd_namespace
    }
    spec = {
      project = "default"
      source  = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_revision
        path           = "apps/http-echo"
        helm = { valueFiles = ["values.yaml"] }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.app_namespace
      }
      syncPolicy = {
        automated = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}
