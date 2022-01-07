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
# Module call
######################################################################

# Creating the Resource Group

module "ResourceGroup" {
  count                                   = length(var.ResourceGroupSuffixList)
  #Module Location
  source                                  = "github.com/dfrappart/Terra-AZModuletest//Modules_building_blocks//003_ResourceGroup/"
  #Module variable      
  RGSuffix                                = "-${var.ResourcesSuffix}-${element(var.ResourceGroupSuffixList,count.index)}"
  RGLocation                              = var.AzureRegion
  ResourceOwnerTag                        = var.ResourceOwnerTag
  CountryTag                              = var.CountryTag
  CostCenterTag                           = var.CostCenterTag
  EnvironmentTag                          = var.Environment
  Project                                 = var.Project

}



module "SpokeVNet" {
  for_each                                = local.SpokeVnetConfig
  
  #Module Location
  source                                  = "github.com/dfrappart/Terra-AZModuletest//Custom_Modules/IaaS_NTW_VNet_for_AppGW/"

  #Module variable
  RGLogName                               = data.azurerm_resource_group.RGLog.name
  LawSubLogName                           = data.azurerm_log_analytics_workspace.LAWLog.name
  STALogId                                = data.azurerm_storage_account.STALog.id
  TargetRG                                = module.ResourceGroup[each.value.TargetRGIndex].RGName
  TargetLocation                          = module.ResourceGroup[each.value.TargetRGIndex].RGLocation
  VNetSuffix                              = each.value.VNetSuffix
  IsBastionEnabled                        = each.value.IsBastionEnabled
  VNetAddressSpace                        = [each.value.VNetAddressSpace]
  ResourceOwnerTag                        = var.ResourceOwnerTag
  CountryTag                              = var.CountryTag
  CostCenterTag                           = var.CostCenterTag
  Environment                             = var.Environment
  Project                                 = var.Project

}

######################################################################
# Adding IP groups for FW usage

resource "azurerm_ip_group" "VNetIPGroups" {
  for_each                                = local.SpokeVnetConfig
  name                                    = "ipgroup-${module.SpokeVNet[each.key].VNetFullOutput.name}"
  location                                = module.ResourceGroup[each.value.TargetRGIndex].RGLocation
  resource_group_name                     = module.ResourceGroup[each.value.TargetRGIndex].RGName

  cidrs                                   = module.SpokeVNet[each.key].VNetFullOutput.address_space

  tags                                    = merge(var.DefaultTags, {"IPGroupType" = "VNet"})
}


######################################################################
# Adding DNS and DNS link

module "PrivDNS" {

  #Module location
  source = "github.com/dfrappart/Terra-AZModuletest//Modules_building_blocks//241_PrivateDNSZone/"
  
  #Module variable
  PrivateDNSDomainName                  = "aro.internalninja"
  RGName                                = module.ResourceGroup[2].RGName

}


resource "azurerm_private_dns_zone_virtual_network_link" "arovnetdnslink" {
  for_each                                = local.SpokeVnetConfig
  name                                    = "dnslink-${module.SpokeVNet[each.key].VNetFullOutput.name}-${module.PrivDNS.PrivateDNSZoneFull.name}"
  resource_group_name                     = module.ResourceGroup[2].RGName
  private_dns_zone_name                   = "aro.internalninja"
  virtual_network_id                      = module.SpokeVNet[each.key].VNetFullOutput.id
}

######################################################################
# Virtual WAN

resource "azurerm_virtual_wan" "vwan" {
  name                                    = "vwan-${var.ResourcesSuffix}"
  resource_group_name                     = module.ResourceGroup[2].RGName
  location                                = module.ResourceGroup[2].RGLocation
  disable_vpn_encryption                  = false
  allow_branch_to_branch_traffic          = true
  office365_local_breakout_category       = "None"
  type                                    = "Standard"

}

resource "azurerm_virtual_hub" "vhub" {
  name                                    = "vhub-${var.ResourcesSuffix}"
  resource_group_name                     = module.ResourceGroup[2].RGName
  location                                = module.ResourceGroup[2].RGLocation
  virtual_wan_id                          = azurerm_virtual_wan.vwan.id
  address_prefix                          = "10.0.0.0/23"
}

resource "azurerm_virtual_hub_connection" "spk_to_vhub" {
  for_each                                = local.SpokeVnetConfig
  name                                    = "${module.SpokeVNet[each.key].VNetFullOutput.name}_to_${azurerm_virtual_hub.vhub.name}"
  virtual_hub_id                          = azurerm_virtual_hub.vhub.id
  remote_virtual_network_id               = module.SpokeVNet[each.key].VNetFullOutput.id
  internet_security_enabled               = true

  routing {

    associated_route_table_id             = azurerm_virtual_hub_route_table.SpokeRT.id
    propagated_route_table {
      route_table_ids                     = [azurerm_virtual_hub_route_table.SpokeRT.id]
      labels                              = azurerm_virtual_hub_route_table.SpokeRT.labels
    }
  }
}


resource "azurerm_virtual_hub_route_table" "SpokeRT" {
  name                                    = "rt-spktohubfw"
  virtual_hub_id                          = azurerm_virtual_hub.vhub.id
  labels                                  = ["SpkToHubFW"]
}


resource "azurerm_virtual_hub_route_table_route" "SpokeToInternet" {
  route_table_id                          = azurerm_virtual_hub_route_table.SpokeRT.id

  name                                    = "SpokeToInternet"
  destinations_type                       = "CIDR"
  destinations                            = ["0.0.0.0/0"]
  next_hop_type                           = "ResourceId"
  next_hop                                = module.HubFirewall.Id
}


resource "azurerm_virtual_hub_route_table_route" "SpokeToSpoke" {
  for_each                                = local.SpokeVnetConfig
  route_table_id                          = azurerm_virtual_hub_route_table.SpokeRT.id

  name                                    = "rou-${azurerm_ip_group.VNetIPGroups[each.key].name}"
  destinations_type                       = "CIDR"
  destinations                            = azurerm_ip_group.VNetIPGroups[each.key].cidrs
  next_hop_type                           = "ResourceId"
  next_hop                                = module.HubFirewall.Id
}



######################################################################
# Azure Firewall

module "HubFirewall" {
  #Module location
  source = "../../Modules/231_AzureFW"

  #Module variable
  STALogId                                = data.azurerm_storage_account.STALog.id
  LawLogId                                = data.azurerm_log_analytics_workspace.LAWLog.id
  TargetRG                                = module.ResourceGroup[2].RGName
  TargetLocation                          = module.ResourceGroup[2].RGLocation
  FWSkuName                               = "AZFW_Hub"
  FWVHubId                                = azurerm_virtual_hub.vhub.id
  FWPolicyId                              = azurerm_firewall_policy.FWPolicy.id


  ResourceOwnerTag                        = var.ResourceOwnerTag
  CountryTag                              = var.CountryTag
  CostCenterTag                           = var.CostCenterTag
  Environment                             = var.Environment
  Project                                 = var.Project

}

######################################################################
# Azure Firewall Policy

resource "azurerm_firewall_policy" "FWPolicy" {
  name                                    = "fw-pol${var.ResourcesSuffix}"
  resource_group_name                     = module.ResourceGroup[2].RGName
  location                                = module.ResourceGroup[2].RGLocation

  sku                                     = "Standard"

  insights {
    enabled                               = true
    default_log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.LAWLog.id
    retention_in_days                     = 31


  }


}


resource "azurerm_firewall_policy_rule_collection_group" "AROFWRules" {
  name                                    = "arocollectionrule"
  firewall_policy_id                      = azurerm_firewall_policy.FWPolicy.id
  priority                                = "2000"

  application_rule_collection {
    name                                  = "aro"
    action                                = "Allow"
    priority                              = "2001"

    rule {
      name                                = "aroegressforinstall"
      source_addresses                    = concat(module.SpokeVNet["Spoke3"].FESubnetFullOutput.address_prefixes,module.SpokeVNet["Spoke3"].BESubnetFullOutput.address_prefixes)
      destination_fqdns                   = [                                            
                                              "*.quay.io",
                                              "registry.redhat.io",
                                              "sso.redhat.com",
                                              "openshift.org"

                                          ]

      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }
    }

    rule {
      name                                = "aroegressfortelemetry"
      source_addresses                    = concat(module.SpokeVNet["Spoke3"].FESubnetFullOutput.address_prefixes,module.SpokeVNet["Spoke3"].BESubnetFullOutput.address_prefixes)
      destination_fqdns                   = [                                            
                                              "cert-api.access.redhat.com",
                                              "api.access.redhat.com",
                                              "infogw.api.openshift.com",
                                              "cloud.redhat.com"

                                          ]

      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }
    }

    rule {
      name                                = "aroegresscloudapi"
      source_addresses                    = concat(module.SpokeVNet["Spoke3"].FESubnetFullOutput.address_prefixes,module.SpokeVNet["Spoke3"].BESubnetFullOutput.address_prefixes)
      destination_fqdns                   = [                                            
                                              "management.azure.com",
                                          ]

      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }
    }

    rule {
      name                                = "aroegressothers"
      source_addresses                    = concat(module.SpokeVNet["Spoke3"].FESubnetFullOutput.address_prefixes,module.SpokeVNet["Spoke3"].BESubnetFullOutput.address_prefixes)
      destination_fqdns                   = [                                            
                                              "mirror.openshift.com",
                                              "storage.googleapis.com",
                                              "aro.internalninja",
                                              "api.openshift.com",
                                              "registry.access.redhat.com"
                                          ]

      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }
    }

    rule {
      name                                = "aroegressmonitoringmsrh"
      source_addresses                    = concat(module.SpokeVNet["Spoke3"].FESubnetFullOutput.address_prefixes,module.SpokeVNet["Spoke3"].BESubnetFullOutput.address_prefixes)
      destination_fqdns                   = [                                            
                                              "login.microsoftonline.co",
                                              "gcs.prod.monitoring.core.windows.net",
                                              "*.blob.core.windows.net",
                                              "*.servicebus.windows.net",
                                              "*.table.core.windows.net"
                                          ]

      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }
    }

  }



}



resource "azurerm_firewall_policy_rule_collection_group" "Spk2FWRules" {
  name                                    = "Spk2FWRules"
  firewall_policy_id                      = azurerm_firewall_policy.FWPolicy.id
  priority                                = 3000


  network_rule_collection {
    name                                  = "AllowFromSpk2tospk"
    action                                = "Allow"
    priority                              = 3001

    dynamic "rule" {
      for_each = local.SpokeVnetConfig
      content {
        name                              = "AllowFromSpk2to${rule.value.VNetSuffix}"
        protocols                         = ["Any"]
        source_ip_groups                  = [azurerm_ip_group.VNetIPGroups["Spoke2"].id]
        destination_addresses             = [rule.value.VNetAddressSpace]
        #destination_ip_groups             = azurerm_ip_group.VNetIPGroups[each.key].id
        destination_ports                 = ["*"]

      }
    }
  }

  application_rule_collection {
    name                                  = "choco"
    action                                = "Allow"
    priority                              = 3002

    rule {
      name                                = "AllowFromSpk2toChoco"
      
      protocols {
        type                              = "Http"
        port                              = 80
      }

      protocols {
        type                              = "Https"
        port                              = 443
      }        
        
      source_ip_groups                    = [azurerm_ip_group.VNetIPGroups["Spoke2"].id]
      destination_fqdns                   = [
                                              "*.chocolatey.org",
                                              "*.github.com",
                                              "*.helm.sh"
                                          ]

      }
  }


}



resource "azurerm_firewall_policy_rule_collection_group" "DefaultEgress" {
  name                                    = "defaultegress"
  firewall_policy_id                      = azurerm_firewall_policy.FWPolicy.id
  priority                                = 4000

  network_rule_collection {
    name     = "AllowAzureCloudEgress"
    priority = 4001
    action   = "Allow"
    rule {
      name                  = "AllowFromAnyToAzureCloud"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["*"]
    }

  }

  network_rule_collection {
    name     = "DenyInternetEgress"
    priority = 4002
    action   = "Deny"
    rule {
      name                  = "genericnetworkruledeny"
      protocols             = ["Any"]
      source_addresses      = ["*"]
      destination_addresses = ["Internet"]
      destination_ports     = ["*"]
    }
  }



}


######################################################################
# VM

module "SecretTest_to_KV" {

  for_each                                = {
    for k,v in local.SpokeVnetConfig : k=>v if v.IsVMDeployed == true
    }
  #Module Location
  source                                  = "github.com/dfrappart/Terra-AZModuletest/Modules_building_blocks/412_KeyvaultSecret/"

  #Module variable     
  KeyVaultSecretSuffix                    = "VMPwd-${each.key}-${var.ResourcesSuffix}"
  #PasswordValue                           = module.SecretTest.Result
  KeyVaultId                              = data.azurerm_key_vault.keyvault.id
  ResourceOwnerTag                        = var.ResourceOwnerTag
  CountryTag                              = var.CountryTag
  CostCenterTag                           = var.CostCenterTag
  Environment                             = var.Environment
  Project                                 = var.Project

  depends_on = [

  ]

}

module "VMWin" {

  for_each                                = {
    for k,v in local.SpokeVnetConfig : k=>v if v.IsVMDeployed == true
    }
  #Module Location
  source                                  = "../../Modules/IaaS_CPT_VMWinwDataDisk_NotLoadBalanced/"

  #Module variable
  LawLogId                                = data.azurerm_log_analytics_workspace.LAWLog.id
  STALogId                                = data.azurerm_storage_account.STALog.id
  TargetRG                                = module.ResourceGroup[3].RGName
  TargetLocation                          = module.SpokeVNet[each.key].VNetFullOutput.location
  TargetSubnetId                          = module.SpokeVNet[each.key].FESubnetFullOutput.id
  STABlobURI                              = data.azurerm_storage_account.STALog.primary_blob_endpoint
  VMSuffix                                = "${each.key}-${var.ResourcesSuffix}"
  VmSize                                  = "Standard_D2s_v3"
  OSDiskTier                              = "StandardSSD_LRS"
  #CloudinitscriptPath                     = var.CloudinitscriptPath
  VmAdminPassword                         = module.SecretTest_to_KV[each.key].SecretFullOutput.value


  DefaultTags                             = var.DefaultTags
}


######################################################################
# allow https on agw

module "NSGRuleRDPAllow_FromBastionSpk2" {
  
  #Module location
  source = "../../Modules/222_NSGRule/"

  #Module variable
  RuleSuffix                      = "RDPAllow_FromBastionSpk2"
  RulePriority                    = 1011
  RuleDirection                   = "Inbound"
  RuleAccess                      = "Allow"
  RuleProtocol                    = "Tcp"
  RuleDestPorts                    = [3389]
  RuleSRCAddressPrefix            = module.SpokeVNet["Spoke2"].AzureBastionSubnetFullOutput.address_prefix
  RuleDestAddressPrefix           = module.SpokeVNet["Spoke1"].FESubnetFullOutput.address_prefix
  TargetRG                        = module.SpokeVNet["Spoke1"].FESubnetNSGFullOutput.resource_group_name
  TargetNSG                       = module.SpokeVNet["Spoke1"].FESubnetNSGFullOutput.name


}

module "NSGRuleRDPAllow_FromSubFESpk2" {
  
  #Module location
  source = "../../Modules/222_NSGRule/"

  #Module variable
  RuleSuffix                      = "RDPAllow_FromSubFESpk2"
  RulePriority                    = 1012
  RuleDirection                   = "Inbound"
  RuleAccess                      = "Allow"
  RuleProtocol                    = "Tcp"
  RuleDestPorts                    = [3389]
  RuleSRCAddressPrefix            = module.SpokeVNet["Spoke2"].FESubnetFullOutput.address_prefix
  RuleDestAddressPrefix           = module.SpokeVNet["Spoke1"].FESubnetFullOutput.address_prefix
  TargetRG                        = module.SpokeVNet["Spoke1"].FESubnetNSGFullOutput.resource_group_name
  TargetNSG                       = module.SpokeVNet["Spoke1"].FESubnetNSGFullOutput.name


}

module "NSGRuleRDPAllow_FromSubFESpk1" {
  
  #Module location
  source = "../../Modules/222_NSGRule/"

  #Module variable
  RuleSuffix                      = "RDPAllow_FromSubFESpk2"
  RulePriority                    = 1011
  RuleDirection                   = "Inbound"
  RuleAccess                      = "Allow"
  RuleProtocol                    = "Tcp"
  RuleDestPorts                    = [3389]
  RuleSRCAddressPrefix            = module.SpokeVNet["Spoke1"].FESubnetFullOutput.address_prefix
  RuleDestAddressPrefix           = module.SpokeVNet["Spoke2"].FESubnetFullOutput.address_prefix
  TargetRG                        = module.SpokeVNet["Spoke2"].FESubnetNSGFullOutput.resource_group_name
  TargetNSG                       = module.SpokeVNet["Spoke2"].FESubnetNSGFullOutput.name


}