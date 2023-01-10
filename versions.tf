terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.14.0"
    }
  }
  required_version = ">= 1.1.2"

  backend "azurerm" {
    storage_account_name = "cdcterraformstates"
    container_name       = "aks-weu"
    resource_group_name  = "CDC-TERRAFORM"
    key                  = "prometheus-stacks/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = "47abbbbc-b105-437d-9a5f-1d3953dc944f"
  environment     = "public"
}

data "terraform_remote_state" "aks-cluster" {
  backend = "azurerm"
  config = {
    storage_account_name = "cdcterraformstates"
    container_name       = "aks-weu"
    resource_group_name  = "CDC-TERRAFORM"
    key                  = "clusters/terraform.tfstateenv:${var.environment}-${var.zone}"
  }
}

locals {
  kube_config           = length(data.terraform_remote_state.aks-cluster.outputs.kubernetes_cluster.kube_admin_config) > 0 ? data.terraform_remote_state.aks-cluster.outputs.kubernetes_cluster.kube_admin_config.0 : data.terraform_remote_state.aks-cluster.outputs.kubernetes_cluster.kube_config.0
  ressource_groupe_name = data.terraform_remote_state.aks-cluster.outputs.ressource_group_name
}

provider "kubernetes" {
  host                   = local.kube_config.host
  cluster_ca_certificate = base64decode(local.kube_config.cluster_ca_certificate)
  client_certificate     = base64decode(local.kube_config.client_certificate)
  client_key             = base64decode(local.kube_config.client_key)
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.host
    cluster_ca_certificate = base64decode(local.kube_config.cluster_ca_certificate)
    client_certificate     = base64decode(local.kube_config.client_certificate)
    client_key             = base64decode(local.kube_config.client_key)
  }
}
