terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
provider "azurerm" {
  features {} 
  subscription_id  = "your-subscription-id-here"
  client_id = "your-client-id-here"
  tenant_id = "your-tenant-id-here"
  client_secret = "your-client-secret-here"
}

data "azurerm_resource_group" "rg" {
  name     = "terraform-rg"
}

locals {
  rg_info = data.azurerm_resource_group.rg
}
data "azurerm_virtual_network" "vnet1" {
  name                = "terraformVnet01"
  resource_group_name = local.rg_info.name
  
}

data "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  virtual_network_name = data.azurerm_virtual_network.vnet1.name
  resource_group_name = local.rg_info.name
  
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg1"
  resource_group_name = "${local.rg_info.name}"
  location            = "${local.rg_info.location}"
}

# NOTE: this allows RDP from any network
resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  resource_group_name         = "${local.rg_info.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = data.azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                            = "${var.prefix}.vmt01"
  computer_name                   = "vm01"
  resource_group_name             = local.rg_info.name
  location                        = local.rg_info.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  network_interface_ids = [ azurerm_network_interface.nic1.id ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}