######################################################################
# config variables 
######################################################################






Project                             = "vwan"
Environment                         = "lab"

ResourcesSuffix                     = "vwan"
ResourceGroupSuffixList             = ["spk1","spk2","vhub","cpt","spkaro"]

DefaultTags                         = {
    ResourceOwner                       = "That would be me"
    Country                             = "fr"
    CostCenter                          = "labtf"
    Project                             = "vwan"
    Environment                         = "lab"
    ManagedBy                           = "Terraform"

  }