locals {
  vm_name_format = "${var.compute["name"]}-%02d"

  # lb_name        = "${var.lb["ip_type"] == "public" ? "${var.compute["name"]}-lb" : "${var.compute["name"]}-ilb"}"
}

data "azurerm_subnet" "subnet" {
  resource_group_name  = "${var.subnet["vnet_resource_group_name"]}"
  virtual_network_name = "${var.subnet["vnet_name"]}"
  name                 = "${var.subnet["name"]}"
}

data "azurerm_storage_account" "storage_account" {
  resource_group_name = "${var.storage_account["resource_group_name"]}"
  name                = "${var.storage_account["name"]}"
}

data "azurerm_snapshot" "snapshot" {
  resource_group_name = "${var.snapshot["resource_group_name"]}"
  name                = "${var.snapshot["name"]}"
}

resource "azurerm_network_interface" "nics" {
  count               = "${length(var.computes)}"
  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-nic"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"

  ip_configuration {
    name      = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-ip-config"
    subnet_id = "${data.azurerm_subnet.subnet.id}"

    private_ip_address_allocation = "${lookup(var.computes[count.index], "private_ip_address", "") != "" ? "static" : "dynamic"}"
    private_ip_address            = "${lookup(var.computes[count.index], "private_ip_address", "")}"

    # load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.bepool.id}"]
  }
}

resource "azurerm_availability_set" "avset" {
  count = "${var.avset["exists"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${var.avset["name"] != "" ? var.avset["name"] : "${var.compute["name"]}-avset"}"
  location = "${var.avset["location"]}"

  platform_fault_domain_count  = "${var.avset["platform_fault_domain_count"]}"
  platform_update_domain_count = "${var.avset["platform_update_domain_count"]}"

  managed = "${var.avset["managed"]}"
}

resource "azurerm_managed_disk" "os_disks" {
  count = "${length(var.computes)}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-os-disk"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"

  create_option        = "Copy"
  storage_account_type = "${lookup(var.computes[count.index], "os_disk_type", var.compute["os_disk_type"])}"
  disk_size_gb         = "${lookup(var.computes[count.index], "os_disk_size_gb", var.compute["os_disk_size_gb"])}"

  source_resource_id = "${data.azurerm_snapshot.snapshot.id}"
}

resource "azurerm_virtual_machine" "vms" {
  count = "${length(var.computes)}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"
  vm_size  = "${lookup(var.computes[count.index], "vm_size", var.compute["vm_size"])}"

  storage_os_disk {
    name = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-os-disk"

    os_type         = "${var.compute["os_type"]}"
    caching         = "ReadWrite"
    create_option   = "Attach"
    managed_disk_id = "${element(azurerm_managed_disk.os_disks.*.id, count.index)}"
  }

  delete_os_disk_on_termination = "${lookup(var.computes[count.index], "os_disk_on_termination", var.compute["os_disk_on_termination"])}"

  network_interface_ids = ["${element(azurerm_network_interface.nics.*.id, count.index)}"]
  availability_set_id   = "${var.avset["exists"] ? "${join("", azurerm_availability_set.avset.*.id)}" : ""}"

  boot_diagnostics {
    enabled     = "${var.compute["boot_diagnostics_enabled"] ? lookup(var.computes[count.index], "boot_diagnostics_enabled", var.compute["boot_diagnostics_enabled"]) : false}"
    storage_uri = "${data.azurerm_storage_account.storage_account.primary_blob_endpoint}"
  }

  depends_on = [
    "azurerm_network_interface.nics",
    "azurerm_availability_set.avset",
    "azurerm_managed_disk.os_disks",
  ]
}
