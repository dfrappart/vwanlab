##############################################################
#This module allows the creation of Route table
##############################################################

##############################################################
# Log variables section

#The Name of the FW

variable "STALogId" {
  type                    = string
  description             = "Specifies the id of the storage account used for logs."

}

variable "LawLogId" {
  type                    = string
  description             = "Specifies the id of the log analytics workspace used for logs."

}

##############################################################
# FW variables section

#The Name of the FW

variable "FWName" {
  type                    = string
  description             = "Specifies the name of the Firewall. Changing this forces a new resource to be created."
  default                 = "-1"
}

#The RG in which the route table is attached to

variable "TargetRG" {
  type                    = string
  description             = "The name of the resource group in which to create the resource. Changing this forces a new resource to be created."

}

#The location of the FW

variable "TargetLocation" {
  type                    = string
  description             = " Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

#The Sku name of the FW

variable "FWSkuName" {
  type                    = string
  description             = "Sku name of the Firewall. Possible values are AZFW_Hub and AZFW_VNet. Changing this forces a new resource to be created."
}

#The Sku tier of the FW

variable "FWSkuTier" {
  type                    = string
  description             = "Sku tier of the Firewall. Possible values are Premium and Standard. Changing this forces a new resource to be created."
  default                 = "Standard"
}

#DNSServer

variable "DNSServer" {
  type                    = list
  description             = "A list of DNS servers that the Azure Firewall will direct DNS traffic to the for name resolution."
  default                 = null
}

# FW Zones

variable "FWZones" {
  type                    = list
  description             = "A list of DNS servers that the Azure Firewall will direct DNS traffic to the for name resolution."
  default                 = ["1","2","3"]
}

# Private IP Ranges for SNAT

variable "FWPrivIPRanges" {
  type                    = list
  description             = " A list of SNAT private CIDR IP ranges, or the special string IANAPrivateRanges, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918."
  default                 = ["IANAPrivateRanges"]
}

# Firewall Policy Id

variable "FWPolicyId" {
  type                    = string
  description             = "The ID of the Firewall Policy applied to this Firewall."
  default                 = null
}

# Firewall Threat Intel mode

variable "FWThreatIntelMode" {
  type                    = string
  description             = "The operation mode for threat intelligence-based filtering. Possible values are: Off, Alert,Deny and (empty string). Defaults to Alert."
  default                 = "Alert"
}

##############################################################
# FW IP config variable section

# The id of the subnet on which the FW is located

variable "FWSubnetId" {
  type                    = string
  description             = "Reference to the subnet associated with the IP Configuration"
  default                 = "empty"
}


##############################################################
# Virtual Hub block variable section

# The id of the subnet on which the FW is located

variable "FWVHubId" {
  type                    = string
  description             = "Specifies the ID of the Virtual Hub where the Firewall resides in."

}

variable "FWVHubPubIPCount" {
  type                    = string
  description             = "Specifies the number of public IPs to assign to the Firewall. Defaults to 1."
  default                 = null
}

variable "FWLogCategories" {
  type                    = map(object({
    LogCategoryName       = string
    LogRetention          = string
  }))
  description             = "The log categories for an Azure Firewall"
  default                 = {
    "LogCategory1" = {
      LogCategoryName     = "AzureFirewallApplicationRule"
      LogRetention        = 365
    }
  
    "LogCategory2" = {
      LogCategoryName     = "AzureFirewallNetworkRule"
      LogRetention        = 365
    }
  
    "LogCategory3" = {
      LogCategoryName     = "AzureFirewallDnsProxy"
      LogRetention        = 365
    }
  }
}

variable "PubIpLogCategories" {
  type                    = map(object({
    LogCategoryName       = string
    LogRetention          = string
  }))
  description             = "The log categories for a Public IP"
  default                 = {
    "LogCategory1" = {
      LogCategoryName     = "DDoSProtectionNotifications"
      LogRetention        = 365
    }
  
    "LogCategory2" = {
      LogCategoryName     = "DDoSMitigationFlowLogs"
      LogRetention        = 365
    }
  
    "LogCategory3" = {
      LogCategoryName     = "DDoSMitigationReports"
      LogRetention        = 365
    }
  }
}

######################################################
# Tag related variables and naming convention section

variable "ResourceOwnerTag" {
  type                              = string
  description                       = "Tag describing the owner"
  default                           = "That would be me"
}

variable "CountryTag" {
  type                              = string
  description                       = "Tag describing the Country"
  default                           = "fr"
}

variable "CostCenterTag" {
  type                              = string
  description                       = "Tag describing the Rexel Cost Center which is the same as the one on the EA"
  default                           = "tflab"
}

variable "Project" {
  type                              = string
  description                       = "The name of the project"
  default                           = "azure"
}

variable "Environment" {
  type                              = string
  description                       = "The environment, dev, prod..."
  default                           = "lab"
}

variable "extra_tags" {
  type        = map
  description = "Additional optional tags."
  default     = {}
}