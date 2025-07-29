terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

# Lookup resource group
data "azurerm_resource_group" "rg" {
  name = "terraform-rg"
}

locals {
  rg_info = data.azurerm_resource_group.rg
}

# Lookup VNet
data "azurerm_virtual_network" "vnet1" {
  name                = "terraformVnet01"
  resource_group_name = local.rg_info.name
}

# Lookup Subnet
data "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  virtual_network_name = data.azurerm_virtual_network.vnet1.name
  resource_group_name  = local.rg_info.name
}

# Create NSG
resource "azurerm_network_security_group" "nsg1" {
  name                = "terraform-nsg1"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location
}

# Allow SSH
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.rg_info.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}

# Associate NSG to Subnet
resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = data.azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Public IP
resource "azurerm_public_ip" "pip1" {
  name                = "terraform-pip"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC with Public IP
resource "azurerm_network_interface" "nic1" {
  name                = "terraform-nic"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

# Virtual Machine with File Provisioner
resource "azurerm_linux_virtual_machine" "main" {
  name                  = "terraform-vm01"
  resource_group_name   = local.rg_info.name
  location              = local.rg_info.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.nic1.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "demo-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name = "myvm"

  provisioner "local-exec" {

  command = "echo ${azurerm_public_ip.pip1.ip_address} >> public_ip.txt"
  }
}