locals {

  defaultIpConfigOutput = {
    "name" = "afw-pubip-config"
    "public_ip_address_id" = "/subscriptions/00000000-0000-0000-0000-00000000000/resourceGroups/<rg_name>/providers/Microsoft.Network/publicIPAddresses/<bst-pubip>"
    "subnet_id" = "/subscriptions/00000000-0000-0000-0000-00000000000/resourceGroups/<rg_name>/providers/Microsoft.Network/virtualNetworks/vnetpocdoc/subnets/AzureBastionSubnet"

    }



  DefaultTags = tomap({
    ResourceOwner                       = var.ResourceOwnerTag
    Country                             = var.CountryTag
    CostCenter                          = var.CostCenterTag
    Project                             = var.Project
    Environment                         = var.Environment
    ManagedBy                           = "Terraform"
  })

}