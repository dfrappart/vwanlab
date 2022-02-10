##############################################################
#This module allows the creation of an AzureRM FW
##############################################################

###################################################################################
# Public Ip for Application Gateway

resource "azurerm_public_ip" "FWPubIP" {
  count                                 = var.FWSkuName == "AZFW_Hub" ? 0 : 1
  name                                  = "pubip-afw${var.FWName}"
  location                              = var.TargetLocation
  resource_group_name                   = var.TargetRG
  allocation_method                     = "Static"
  sku                                   = "standard"
  domain_name_label                     = "pubip-afw${lower(var.FWName)}"


  tags = merge(local.DefaultTags, var.extra_tags)
}

#Diagnostic settings on the FW pub ip

resource "azurerm_monitor_diagnostic_setting" "FWPubIPDiag" {
  count                                 = var.FWSkuName == "AZFW_Hub" ? 0 : 1
  name                                  = "diag-${azurerm_public_ip.FWPubIP[count.index].name}"
  target_resource_id                    = azurerm_public_ip.FWPubIP[count.index].id
  storage_account_id                    = var.STALogId
  log_analytics_workspace_id            = var.LawLogId

  dynamic "log" {
    for_each                            = var.PubIpLogCategories
    content {
      category                            = log.value.LogCategoryName
      enabled                             = true
      retention_policy {
        enabled                           = true
        days                              = log.value.LogRetention
      } 
    }

  }


  metric {
    category                            = "AllMetrics"
    enabled                             = true
    retention_policy {
      enabled                           = true
      days                              = 365
    }    

  }
}

# FW creation

resource "azurerm_firewall" "AzureFirewall" {
  name                                      = "afw${var.FWName}"
  location                                  = var.TargetLocation
  resource_group_name                       = var.TargetRG
  sku_name                                  = var.FWSkuName
  sku_tier                                  = var.FWSkuTier
  firewall_policy_id                        = var.FWPolicyId
  dns_servers                               = var.DNSServer
  zones                                     = var.FWZones
  threat_intel_mode                         = var.FWSkuName == "AZFW_Hub" ? "" : var.FWThreatIntelMode
  private_ip_ranges                         = var.FWPrivIPRanges

  #ip_configuration {
  #  name                                    = "ipconfig-afw${var.FWName}"
  #  subnet_id                               = var.FWSubnetId
  #  public_ip_address_id                    = azurerm_public_ip.FWPubIP.id
  #}

  virtual_hub {
    virtual_hub_id                          = var.FWVHubId
    public_ip_count                         = var.FWVHubPubIPCount
  }

  tags = merge(local.DefaultTags, var.extra_tags)

}


#Diagnostic settings on the FW

resource "azurerm_monitor_diagnostic_setting" "FWDiag" {
  name                                  = "diag-${azurerm_firewall.AzureFirewall.name}"
  target_resource_id                    = azurerm_firewall.AzureFirewall.id
  storage_account_id                    = var.STALogId
  log_analytics_workspace_id            = var.LawLogId

  dynamic "log" {
    for_each                            = var.FWLogCategories
    content {
      category                            = log.value.LogCategoryName
      enabled                             = true
      retention_policy {
        enabled                           = true
        days                              = log.value.LogRetention
      } 
    }

  }


  metric {
    category                            = "AllMetrics"
    enabled                             = true
    retention_policy {
      enabled                           = true
      days                              = 365
    }    

  }
}
