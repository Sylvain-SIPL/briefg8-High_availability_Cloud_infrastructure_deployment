provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}


###########  describe VNET ############

resource "azurerm_virtual_network" "v-net" {
  name                = "vnet-hks"
  address_space       = ["10.120.8.0/22"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
}


######### describe subnet web server ###########

resource "azurerm_subnet" "snet-websrv" {
  name                 = "snet-websrv"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.120.8.0/24"]
}

######## describe subnet business #############

resource "azurerm_subnet" "snet-business" {

  name                 = "snet-business"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.120.9.0/24"]
}


######## describe subnet internal load balancer ######

resource "azurerm_subnet" "snet-ilb" {
  name                 = "snet-ilb-hks"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.120.10.0/24"]
}

######## describe subnet public load balancer ########

resource "azurerm_subnet" "snet-plb" {
  name                 = "snet-plb-hks"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.120.11.0/24"]
}


################ NIC nginx server ###############

resource "azurerm_network_interface" "nic-nginx-server" {
  count               = 3
  name                = "nic-nginx-server${count.index}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Internal"
    subnet_id                     = azurerm_subnet.snet-websrv.id
    private_ip_address_allocation = "Dynamic"

  }
}


################ NIC business server ###############

resource "azurerm_network_interface" "nic-business" {
  count               = 3
  name                = "nic-business${count.index}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Internal"
    subnet_id                     = azurerm_subnet.snet-websrv.id
    private_ip_address_allocation = "Dynamic"

  }
}



####### generate Vm with packet tracer ############


## generate web server ###########

data "azurerm_image" "web" {
  name                = var.packer_image_name
  resource_group_name = var.resource_group_name
}


resource "azurerm_availability_set" "avset-web" {
  name                = "HKSset"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}

######## create nginx  server #################

resource "azurerm_linux_virtual_machine" "nginx" {

  count                           = 3
  name                            = "nginx-vm-${count.index}"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "admindebian"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic-nginx-server[count.index].id]
  source_image_id                 = data.azurerm_image.web.id
  availability_set_id             = azurerm_availability_set.avset-web.id


  admin_ssh_key {
    username   = "admindebian"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


}


## generate business server ###########

data "azurerm_image" "main" {
  name                = var.packer_image_bus
  resource_group_name = var.resource_group_name
}


resource "azurerm_availability_set" "avset-bus" {
  name                = "HKSset-business"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}


######## create business server #################

resource "azurerm_linux_virtual_machine" "business" {

  count                           = 3
  name                            = "business-vm-${count.index}"
  location                        = var.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = "Standard_B1ls"
  admin_username                  = "admindebian"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic-business[count.index].id]
  source_image_id                 = data.azurerm_image.main.id
  availability_set_id             = azurerm_availability_set.avset-bus.id


  admin_ssh_key {
    username   = "admindebian"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


}






