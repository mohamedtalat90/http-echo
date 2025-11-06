terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48" 
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }

  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
        config_path    = var.kubeconfig_path
  }
}
