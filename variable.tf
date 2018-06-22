# lb
variable "lb" {
  default = {
    required = false
    location = "japaneast"

    domain_name_label     = ""
    ip_address_allocation = "Dynamic"
  }
}

# ilb
variable "ilb" {
  default = {
    required = false
    location = "japaneast"

    vnet_resource_group_name = ""
    vnet_name                = ""
    vnet_subnet_name         = ""

    private_ip_address = ""
  }
}

# virtual_machine
variable "subnet" {
  default = {
    vnet_resource_group_name = ""
    vnet_name                = ""
    name                     = ""
  }
}

variable "storage_account" {
  default = {
    resource_group_name = ""
    name                = ""
  }
}

variable "snapshot" {
  default = {
    resource_group_name = ""
    name                = ""

    uri = ""
  }
}

variable "compute" {
  default = {
    location = "japaneast"
    vm_size  = "Standard_F2"

    os_type = "Linux"

    os_disk_type           = "Standard_LRS"
    os_disk_size_gb        = 60
    os_disk_on_termination = true

    boot_diagnostics_enabled = false
  }
}

variable "computes" {
  default = []
}

# avset
variable "avset" {
  default = {
    required = false

    name     = ""
    location = "japaneast"

    platform_fault_domain_count  = 2
    platform_update_domain_count = 5

    managed = true
  }
}
