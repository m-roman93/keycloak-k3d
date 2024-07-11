terraform {
  required_providers {
    helm = {
      source  = "helm"
      version = "2.10.1"
    }
    kubernetes = {
      source  = "kubernetes"
      version = "2.21.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
    tls = {
      source  = "tls"
      version = "4.0.4"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "k3d-local"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3d-local"
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "k3d-local"
}