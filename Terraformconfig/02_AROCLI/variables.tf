##############################################################
#Variable declaration for provider

variable "AzureSubscriptionID" {
  type                          = string
  description                   = "The subscription id for the authentication in the provider"
}

variable "AzureClientID" {
  type                          = string
  description                   = "The application Id, taken from Azure AD app registration"
}


variable "AzureClientSecret" {
  type                          = string
  description                   = "The Application secret"

}

variable "AzureTenantID" {
  type                          = string
  description                   = "The Azure AD tenant ID"
}

######################################################
# Common variables

variable "AzureRegion" {
  type                            = string
  description                     = "The Azure region for deployment"
  default                         = "westeurope"
}

variable "ResourceOwnerTag" {
  type                            = string
  description                     = "Tag describing the owner"
  default                         = "That would be me"
}

variable "CountryTag" {
  type                            = string
  description                     = "Tag describing the Country"
  default                         = "fr"
}

variable "CostCenterTag" {
  type                            = string
  description                     = "Tag describing the Cost Center"
  default                         = "labaks"
}

variable "Project" {
  type                            = string
  description                     = "The name of the project"
  default                         = "csi"
}

variable "Environment" {
  type                            = string
  description                     = "The environment, dev, prod..."
  default                         = "lab"
}

variable "ResourcesSuffix" {
  type                            = string
  description                     = "The environment, dev, prod..."
  default                         = "csimeetup"
}


######################################################
# Data sources variables

variable "SubsetupSTOAName" {
  type          = string
  description   = "Name of the storage account containing the remote state"
}

variable "SubsetupAccessKey" {
  type          = string
  description   = "Access Key of the storage account containing the remote state"
}

variable "SubsetupContainerName" {
  type          = string
  description   = "Name of the container in the storage account containing the remote state"
}

variable "SubsetupKey" {
  type          = string
  description   = "State key"
}


##############################################
#Variable for using infra state as a data source

variable "statestoa" {
  type    = string
  description = "the name of the storage account storing the state of the infra configuration"
}

variable "statecontainer" {
  type    = string
  description = "The name of the container in which the state is stored"
}

variable "statestoakey" {
  type    = string
  description = "The storage access key of the storage account"
}

variable "statekeyInfraState" {
  type    = string
  description = "the name of the file containing the state of the infra configuration"
}

##############################################
#Variable for configuring aro cli

variable "AROClusterName" {
  type    = string
  description = "the name of the ARO Cluster"
  default = "aro1"
}

variable "AROAPIVisibility" {
  type    = string
  description = "The ARO Cluster API visibility, private or public"
  default = "private"
}

variable "AROIngressVisibility" {
  type    = string
  description = "The ARO Cluster Ingress visibility, private or public"
  default = "private"
}

variable "AROWorkerCount" {
  type    = string
  description = "The ARO Cluster worker count"
  default = 3
}

variable "AROClusterRG" {
  type    = string
  description = "The ARO Cluster Resource Group"
  default = "rg-arocluster"
}

variable "AroCustomDNS" {
  type    = string
  description = "The ARO custom domain"
  default = "aro.internalninja"
}

variable "AroSPId" {
  type    = string
  description = "The ARO serviceprincipal Id"
  default = "aro.internalninja"
}

variable "AroSPSecret" {
  type    = string
  description = "The ARO service principal secret"
  default = "aro.internalninja"
}

variable "AroWorkerVMSize" {
  type    = string
  description = "The ARO worker VM size"
  default = "Standard_D2s_v3"
}

variable "AroMasterVMSize" {
  type    = string
  description = "The ARO master VM size"
  default = "Standard_D2s_v3"
}