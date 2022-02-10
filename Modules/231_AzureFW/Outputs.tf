##############################################################
#This module allows the creation of Route table
##############################################################


#Output

output "Name" {
  value                       = azurerm_firewall.AzureFirewall.name
  sensitive                   = false
}

output "Id" {
  value                       = azurerm_firewall.AzureFirewall.id
  sensitive                   = true
}

output "RGName" {
  value = azurerm_firewall.AzureFirewall.resource_group_name
  sensitive                   = false
}

output "FWFullOutput" {
  value                       = azurerm_firewall.AzureFirewall
  sensitive                   = true
}


output "FWPubIpName" {
  value                       = var.FWSkuName == "AZFW_Hub" ? "AZFW_Hub" : azurerm_public_ip.FWPubIP[0].name
  sensitive                   = true
}

output "FWPubIpId" {
  value                       = var.FWSkuName == "AZFW_Hub" ? "AZFW_Hub" : azurerm_public_ip.FWPubIP[0].id
  sensitive                   = true
}

output "FWPubIpFqdn" {
  value                       = var.FWSkuName == "AZFW_Hub" ? "AZFW_Hub" : azurerm_public_ip.FWPubIP[0].fqdn
  sensitive                   = true
}

output "FWPubIpIpAddress" {
  value                       = var.FWSkuName == "AZFW_Hub" ? "AZFW_Hub" : azurerm_public_ip.FWPubIP[0].ip_address
  sensitive                   = true
}

