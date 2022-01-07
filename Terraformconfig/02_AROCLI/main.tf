######################################################################
# backend block for partial configuration
######################################################################

terraform {
  backend "azurerm" {}
}

######################################################################
# Access to Azure
######################################################################

provider "azurerm" {
  subscription_id                          = var.AzureSubscriptionID
  client_id                                = var.AzureClientID
  client_secret                            = var.AzureClientSecret
  tenant_id                                = var.AzureTenantID

  features {}
  
}



######################################################################
# ARO deployment through az cli

resource "null_resource" "Disable_Policy" {
  #Use this resource to install AGI on CLI
  #count = local.agicaddonstatus == "false" ? 1 : 0
  provisioner "local-exec" {
    command = "az network vnet subnet update --name ${data.azurerm_subnet.mastersubnet.name} --vnet-name ${data.azurerm_virtual_network.InfraVnet.name} --disable-private-link-service-network-policies true --resource-group ${data.azurerm_resource_group.InfraRG.name}" 
  }

  depends_on = [

  ]
}

resource "null_resource" "Install_ARO" {
  #Use this resource to install AGI on CLI
  #count = local.agicaddonstatus == "false" ? 1 : 0
  provisioner "local-exec" {
    command = "az aro create --name ${var.AROClusterName} --vnet ${data.azurerm_virtual_network.InfraVnet.name} --master-subnet ${data.azurerm_subnet.mastersubnet.name} --worker-subnet ${data.azurerm_subnet.workersubnet.name} --apiserver-visibility ${var.AROAPIVisibility} --ingress-visibility ${var.AROIngressVisibility} --location ${var.AzureRegion} --worker-count ${var.AROWorkerCount} --resource-group ${data.azurerm_resource_group.InfraRG.name} --domain ${var.AroCustomDNS} --cluster-resource-group ${var.AROClusterRG} --verbose" 
  }

  depends_on = [
     null_resource.Disable_Policy
  ]
}

