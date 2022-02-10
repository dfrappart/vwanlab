######################################################################
# Webshop K8S + Storage resources
######################################################################

######################################################################
# Access to terraform
######################################################################

terraform {

  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id         = var.AzureSubscriptionID
  client_id               = var.AzureClientID
  client_secret           = var.AzureClientSecret
  tenant_id               = var.AzureTenantID

  features {}
}

provider "kubernetes" {

  host                    = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.host #module.AKSClus.KubeAdminCFG_HostName
  username                = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.username
  password                = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.password
  client_certificate      = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.client_certificate)
  client_key              = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.client_key)
  cluster_ca_certificate  = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.cluster_ca_certificate)

}


provider "helm" {
  kubernetes {

  host                    = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.host #module.AKSClus.KubeAdminCFG_HostName
  username                = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.username
  password                = data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.password
  client_certificate      = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.client_certificate)
  client_key              = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.client_key)
  cluster_ca_certificate  = base64decode(data.azurerm_kubernetes_cluster.AKSCluster.kube_admin_config.0.cluster_ca_certificate)

  }
}

locals {

  ResourcePrefix                        = "${lower(var.Company)}${lower(var.CountryTag)}"

}



######################################################################
# installing cilium from helm

resource "helm_release" "cilium" {
  name                                = "cilium"
  repository                          = "https://helm.cilium.io/"
  chart                               = "cilium"
  version                             = var.CiliumChartVer
  namespace                           = "kube-system"
  #create_namespace                    = true

  dynamic "set" {
    for_each                          = var.HelmCiliumParam
    iterator                          = each
    content {
      name                            = each.value.ParamName
      value                           = each.value.ParamValue
    }

  }

  set {
    name                              = "azure.resourceGroup"
    value                             = data.terraform_remote_state.AKSClus.outputs.AKSNodeRG
  }
  set_sensitive {
    name                              = "azure.subscriptionID"
    value                             = var.AzureSubscriptionID
  }

  set_sensitive {
    name                              = "azure.tenantID"
    value                             = var.AzureTenantID
  }

  set_sensitive {
    name                              = "azure.clientID"
    value                             = var.AzureClientID
  }

  set_sensitive {
    name                              = "azure.clientSecret"
    value                             = var.AzureClientSecret
  }

}

