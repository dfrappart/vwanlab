######################################################
# Subscription Output

output "CurrentSubFullOutput" {

  value             = data.azurerm_subscription.current
}


######################################################
# Cluster Output

output "VNetName" {

  value             = data.azurerm_virtual_network.InfraVnet.name
  sensitive         = true
}

output "MasterSubnet" {

  value             = data.azurerm_subnet.mastersubnet.name
  sensitive         = true
}

output "WorkerSubnet" {

  value             = data.azurerm_subnet.workersubnet.name
  sensitive         = true
}

output "aroclicommand" {
  value = "az aro create --name ${var.AROClusterName} --vnet ${data.azurerm_virtual_network.InfraVnet.name} --master-subnet ${data.azurerm_subnet.mastersubnet.name} --worker-subnet ${data.azurerm_subnet.workersubnet.name} --apiserver-visibility ${var.AROAPIVisibility} --ingress-visibility ${var.AROIngressVisibility} --location ${var.AzureRegion} --worker-count ${var.AROWorkerCount} --resource-group ${data.azurerm_resource_group.InfraRG.name} --domain ${var.AroCustomDNS} --cluster-resource-group ${var.AROClusterRG} --verbose"
}