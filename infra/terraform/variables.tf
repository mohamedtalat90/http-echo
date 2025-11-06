variable "hcloud_token" {
  type      = string
  sensitive = true
}
variable "ssh_public_key_path" {
  type = string
  # e.g. "~/.ssh/id_rsa.pub"
}
variable "server_type" {
  type    = string
  default = "cx33"
  # pick size
}
variable "location" {
  type    = string
  default = "nbg1"
  # or hel1/fsn1
}
variable "image" {
  type    = string
  default = "ubuntu-24.04"
}
variable "hostname" {
  type    = string
  default = "k3s-node-1"
}

# Kubeconfig path on YOUR laptop (where terraform runs)
variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/hetzner-k3s.yaml"
}

# ArgoCD + app namespaces
variable "argocd_namespace" {
  type    = string
  default = "argocd"
}
variable "app_namespace" {
  type    = string
  default = "http-echo"
}

# GitOps
variable "git_repo_url" {
  type    = string
  default = "https://github.com/mohamedtalat90/http-echo.git"
}
variable "git_revision" {
  type    = string
  default = "main"
}

# TLS + domains
variable "base_domain" {
  type = string
  # e.g. example.com or <IP>.sslip.io
}
variable "acme_email" {
  type = string
  # your email for Let's Encrypt
}
