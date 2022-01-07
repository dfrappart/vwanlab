
locals {
    SpokeVnetConfig = {
        "Spoke1" = {
            VNetAddressSpace = "172.20.0.0/24"
            VNetSuffix       = "${var.ResourcesSuffix}${var.ResourceGroupSuffixList[0]}"
            IsBastionEnabled = false
            IsVMDeployed     = true
            TargetRGIndex    = 0

        }
        "Spoke2" = {
            VNetAddressSpace = "172.21.0.0/24"
            VNetSuffix       = "${var.ResourcesSuffix}${var.ResourceGroupSuffixList[1]}"
            IsBastionEnabled = true
            IsVMDeployed     = true
            TargetRGIndex    = 1   
        }
        "Spoke3" = {
            VNetAddressSpace = "172.22.0.0/24"
            VNetSuffix       = "${var.ResourcesSuffix}${var.ResourceGroupSuffixList[4]}"
            IsBastionEnabled = false
            IsVMDeployed     = false
            TargetRGIndex    = 4   
        }
    }


}