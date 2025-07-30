terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
    subscription_id  = "your-subscription-id-here"
    client_id = "your-client-id-here"
    tenant_id = "your-tenant-id-here"
    client_secret = "your-client-secret-here"

}

resource "azurerm_resource_group" "rg" {
  name     = join("", [var.prefix, "rg01"])
  location = "EastUS"
}

resource "azurerm_storage_account" "sa" {
  name                     = lower(join("", [var.prefix, "sa01"]))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-10"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = ["${var.vnet_cidr_prefix}"]
}

resource "azurerm_subnet" "subnet1" {
  count                = 2
  name                 = "subnet1-${count.index}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.subnet1_cidr_prefix[count.index]}"]
}

# resource "azurerm_network_security_group" "nsg1" {
#   name                = "${var.prefix}-nsg1"
#   resource_group_name = "${azurerm_resource_group.rg.name}"
#   location            = "${azurerm_resource_group.rg.location}"
# }

# resource "azurerm_network_security_rule" "rdp" {
#   name                        = "rdp"
#   resource_group_name         = "${azurerm_resource_group.rg.name}"
#   network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
#   priority                    = 102
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "3389"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

# resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
#   subnet_id                 = azurerm_subnet.subnet1.id
#   network_security_group_id = azurerm_network_security_group.nsg1.id
# }

resource "azurerm_network_interface" "nic1" {
  count               = 2 
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  count               = 2
  name                = "${var.prefix}-vmt01-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic1[count.index].id
  ]

  os_disk {
    name                 = "my-os-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


