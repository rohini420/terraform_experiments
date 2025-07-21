# Terraform Azure Infrastructure Setup - Complete Documentation

This document provides a comprehensive overview of setting up Azure infrastructure using Terraform, including all the troubleshooting steps encountered during the process.

## Project Overview

This Terraform configuration creates a complete Azure infrastructure setup including:
- Resource Group
- Virtual Network with subnet
- Network Security Group with RDP rule
- Network Interface
- Windows Virtual Machine

## File Structure

```
azure_example/
├── main.tf           # Main Terraform configuration
├── variables.tf      # Variable definitions
├── terraform.tfvars  # Variable values
└── README.md         # This documentation
```

## Configuration Files

### main.tf
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
  
  subscription_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret   = "your-client-secret-here"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rgname
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-10"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet_cidr_prefix]
}

# Subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  virtual_network_name = azurerm_virtual_network.vnet1.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [var.subnet1_cidr_prefix]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Network Security Rule for RDP
resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Network Interface
resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = "${var.prefix}.vmt01"
  computer_name       = "vm01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic1.id
  ]

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
```

### variables.tf
```hcl
variable "rgname" {
  type        = string
  description = "Used for naming resource group"
}

variable "location" {
  type        = string
  description = "Used for selecting location"
  default     = "eastus"
}

variable "prefix" {
  type        = string
  description = "Used to define standard prefix for all resources"
}

variable "vnet_cidr_prefix" {
  type        = string
  description = "This variable defines address space for vnet"
}

variable "subnet1_cidr_prefix" {
  type        = string
  description = "This variable defines address space for subnet"
}
```

### terraform.tfvars
```hcl
rgname              = "terraform_rg1"
location            = "East US"
prefix              = "terraform_practice"
vnet_cidr_prefix    = "10.10.0.0/16"
subnet1_cidr_prefix = "10.10.1.0/24"
```

## Deployment Process

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Validate Configuration
```bash
terraform validate
```

### Step 3: Plan Deployment
```bash
terraform plan
```

### Step 4: Apply Configuration
```bash
terraform apply --auto-approve
```

## Troubleshooting Journey

### Issue 1: Provider Version Conflict
**Problem:** 
```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/azurerm: 
locked provider registry.terraform.io/hashicorp/azurerm 3.0.0 does not match 
configured version constraint 2.46.0
```

**Solution:** The issue was resolved after running `terraform init` again. The system was able to use the previously installed azurerm v3.0.0 provider.

**Status:** ✅ **SUCCESS** - Provider initialized successfully

---

### Issue 2: Undeclared Resource References
**Problem:**
```
Error: Reference to undeclared resource
on main.tf line 27, in resource "azurerm_virtual_network" "vnet1":
27:   resource_group_name = "${azurerm_resource_group.rgname}"
A managed resource "azurerm_resource_group" "rgname" has not been declared
```

**Root Cause:** Incorrect resource references in the virtual network configuration.

**Solution:** Fixed the resource references to use the correct resource name:
- Changed `"${azurerm_resource_group.rgname}"` to `"${azurerm_resource_group.rg.name}"`
- Changed `"${azurerm_resource_group.location}"` to `"${azurerm_resource_group.rg.location}"`

**Status:** ✅ **SUCCESS** - Configuration validation passed

---

### Issue 3: Invalid CIDR Notation
**Problem:**
```
Error: creating/updating Virtual Network
Code="InvalidAddressPrefixFormat" 
Message="Address prefix 10.10.0.0./16 of resource is not formatted correctly. 
It should follow CIDR notation, for example 10.0.0.0/24."
```

**Root Cause:** Extra period in the CIDR notation: `"10.10.0.0./16"` instead of `"10.10.0.0/16"`

**Solution:** Corrected the CIDR notation in the terraform.tfvars file.

**Status:** ✅ **SUCCESS** - Virtual network created successfully

---

### Issue 4: Windows VM Computer Name Length Restriction
**Problem:**
```
Error: unable to assume default computer name "computer_name" can be at most 15 characters, 
got 23. Please adjust the "name", or specify an explicit "computer_name"
```

**Root Cause:** Windows VM name `"terraform_pratice.vmt01"` (23 characters) exceeded the 15-character limit for Windows computer names.

**Solution:** Added explicit `computer_name = "vm01"` parameter to the Windows VM resource.

**Status:** ✅ **SUCCESS** - Virtual machine created successfully in 36 seconds

---

## Final Results

### Successful Deployment
- **Resources Created:** 8 total resources
- **Deployment Time:** ~1-2 minutes total
- **Final Apply:** 1 resource added (Windows VM) after resolving all issues

### Resources Successfully Created:
1. ✅ Resource Group (`terraform_rg1`)
2. ✅ Network Security Group (`terraform_practice-nsg1`)
3. ✅ Network Security Rule (RDP rule)
4. ✅ Virtual Network (`terraform_practice-10`)
5. ✅ Subnet (`subnet01`)
6. ✅ NSG-Subnet Association
7. ✅ Network Interface (`terraform_practice-nic`)
8. ✅ Windows Virtual Machine (`terraform_practice.vmt01`)

## Key Learnings

### Best Practices Discovered:
1. **Resource References:** Always use proper Terraform resource references (`resource_type.resource_name.attribute`)
2. **CIDR Notation:** Double-check network CIDR formatting for Azure compliance
3. **Naming Conventions:** Consider platform-specific naming limitations (Windows 15-char computer name limit)
4. **Variable Usage:** Leverage variables for reusability and maintainability
5. **Provider Versioning:** Lock provider versions for consistency

### Security Considerations:
- RDP access is currently open to all networks (`*`) - should be restricted in production
- Admin password is hardcoded - should use Azure Key Vault or variables
- Consider using SSH keys instead of passwords for better security

## Commands Reference

```bash
# Initialize Terraform
terraform init

# Upgrade providers if needed
terraform init -upgrade

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Apply with auto-approval
terraform apply --auto-approve

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List resources
terraform state list
```

## Environment Information
- **Terraform Version:** Compatible with provider azurerm v3.0.0
- **Azure Region:** East US
- **VM Size:** Standard_B1s
- **OS:** Windows Server 2019 Datacenter

## Notes
- All sensitive information (subscription IDs, client secrets, etc.) have been sanitized in this documentation
- The infrastructure created includes basic networking and a single Windows VM
- RDP access is enabled on port 3389 for remote management
- Storage uses Standard LRS for cost optimization

---

*Documentation generated from hands-on Terraform Azure deployment experiment*