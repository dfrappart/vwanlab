#############################################################################
#This file is used to define data source refering to Azure existing resources
#############################################################################


#############################################################################
#data sources


data "azurerm_subscription" "current" {}

data "azurerm_client_config" "currentclientconfig" {}




#############################################################################
#data source for subsetup State



data "terraform_remote_state" "Subsetupstate" {
  backend                     = "azurerm"
  config                      = {
    storage_account_name      = var.SubsetupSTOAName
    container_name            = var.SubsetupContainerName
    key                       = var.SubsetupKey
    access_key                = var.SubsetupAccessKey
  }
}

#############################################################################
#data source for AKS


#Data source for remote state

data "terraform_remote_state" "Infra" {
  backend   = "azurerm"
  config    = {
    storage_account_name = var.statestoa
    container_name       = var.statecontainer
    key                  = var.statekeyInfraState
    access_key           = var.statestoakey
  }
}


data "azurerm_resource_group" "InfraRG" {
  name                  = element(data.terraform_remote_state.Infra.outputs.RG_Name,4)
}

data "azurerm_virtual_network" "InfraVnet" {
  name                  = lookup(data.terraform_remote_state.Infra.outputs.VNetName,"Spoke3")
  resource_group_name   = data.azurerm_resource_group.InfraRG.name
}

data "azurerm_subnet" "mastersubnet" {
  name                  = lookup(data.terraform_remote_state.Infra.outputs.FESubnet_VNet_Name,"Spoke3")
  virtual_network_name  = data.azurerm_virtual_network.InfraVnet.name
  resource_group_name   = data.azurerm_resource_group.InfraRG.name
}

data "azurerm_subnet" "workersubnet" {
  name                  = lookup(data.terraform_remote_state.Infra.outputs.BESubnet_VNet_Name,"Spoke3")
  virtual_network_name  = data.azurerm_virtual_network.InfraVnet.name
  resource_group_name   = data.azurerm_resource_group.InfraRG.name
}