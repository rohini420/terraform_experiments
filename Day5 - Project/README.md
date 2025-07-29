# 🔍 Terraform Data Sources (Azure)

This module demonstrates how I leveraged **Terraform Data Sources** to reference and interact with existing Azure resources in a dynamic, reusable, and production-safe way. This was part of my daily Terraform practice and infrastructure experiments.

---

## 🧠 Concept Overview

**Data sources** in Terraform are used to fetch and reference information from existing infrastructure or external systems outside Terraform's control. They allow you to query data (e.g., existing VMs, resource groups, secrets, IPs) and use it in your Terraform configuration without creating or managing that data.

### 📌 Key Benefits
- Reuse resources created outside Terraform
- Read configuration from cloud providers (e.g., secrets from Key Vault)
- Fetch dynamic values (like latest AMI, IPs, etc.)
- Avoid duplication and hardcoding

---

## 📂 Project Architecture

This project demonstrates a **hybrid infrastructure approach** where:
- **Existing resources** (created manually via Azure Portal): Resource Group, Virtual Network, Subnet
- **Terraform-managed resources**: Network Security Group, Network Interface, Virtual Machine

### 🏗️ Infrastructure Layout

```
Azure Portal (Manual)          Terraform (Managed)
├── Resource Group            ├── Network Security Group
├── Virtual Network           ├── Network Security Rules
└── Subnet                    ├── Network Interface
                              └── Windows Virtual Machine
```

---

## 🛠️ Implementation

### Prerequisites Setup
First, create these resources manually in Azure Portal:
1. **Resource Group**: `terraform-rg`
2. **Virtual Network**: `terraformVnet01` (with default IP ranges)
3. **Subnet**: `subnet01` (within the VNet)

### Terraform Configuration

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {} 
  subscription_id = var.subscription_id
  client_id      = var.client_id
  tenant_id      = var.tenant_id
  client_secret  = var.client_secret
}

# Fetch existing Resource Group
data "azurerm_resource_group" "rg" {
  name = "terraform-rg"
}

# Fetch existing Virtual Network
data "azurerm_virtual_network" "vnet1" {
  name                = "terraformVnet01"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Fetch existing Subnet
data "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  virtual_network_name = data.azurerm_virtual_network.vnet1.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

# Create RDP Security Rule
resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  resource_group_name         = data.azurerm_resource_group.rg.name
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
  subnet_id                 = data.azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Create Network Interface
resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = "${var.prefix}.vmt01"
  computer_name       = "vm01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic1.id]

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

### Variables Configuration

```hcl
# variables.tf
variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "terraform_practice"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}
```

---

## 🔧 Deployment Results

After running `terraform apply`, the following resources are created:

| ✅ Resource | 🔹 Type | 📍 Location | 🏷️ Status |
|-------------|---------|-------------|-----------|
| terraform_practice-nic | Network Interface | East US | ✅ Created |
| terraform_practice-nsg1 | Network Security Group | East US | ✅ Created |
| terraform_practice.vmt01 | Windows Virtual Machine | East US | ✅ Created |
| terraform_practice.vmt01_OsDisk | OS Disk (Managed) | East US | ✅ Created |

**Total Resources**: 4 created, 3 referenced via data sources

---

## 🧪 Troubleshooting Experience

### ❌ Common Problems Encountered

#### Problem 1: Resource Not Found Error
```shell
Error: Error reading Resource Group "terraform-rg"
```

**Root Cause**: The specified resource group didn't exist or was misspelled.

**Solution**:
- Verified the resource group existed in Azure Portal
- Ensured correct subscription context was active
- Double-checked resource naming conventions

#### Problem 2: Dependency Conflicts
```shell
Error: Resource depends on resource that cannot be determined until apply
```

**Root Cause**: Tried to reference a resource in a data source that was being created in the same plan.

**Solution**: 
- Data sources can only reference **pre-existing** infrastructure
- Separate creation and referencing into different Terraform runs if needed

#### Problem 3: Authentication Issues
```shell
Error: building AzureRM Client: obtain subscription() from Azure CLI
```

**Root Cause**: Service principal credentials were incorrect or expired.

**Solution**:
- Verified service principal permissions
- Used `terraform.tfvars` for sensitive credential management
- Ensured proper RBAC roles were assigned

---

## ✅ Best Practices Learned

### 🎯 Code Organization
- **Use `locals`** to wrap data source values for better readability
- **Avoid hardcoding** - leverage data sources for dynamic references
- **Separate concerns** - keep manual and Terraform-managed resources clearly documented

### 🔒 Security
- **Never commit credentials** - use `terraform.tfvars` and `.gitignore`
- **Use variable sensitivity** - mark credentials as `sensitive = true`
- **Principle of least privilege** - assign minimal required RBAC roles

### 🚀 Operational
- **Use `terraform console`** to quickly test and debug data source values
- **Plan before apply** - always review what will be created/modified
- **State management** - consider remote state for team collaboration

---

## 🔗 Advanced Usage Patterns

### Using Locals for Cleaner Code
```hcl
locals {
  rg_info   = data.azurerm_resource_group.rg
  vnet_info = data.azurerm_virtual_network.vnet1
  
  common_tags = {
    Environment = "Development"
    Project     = "Terraform-Practice"
    Owner       = "DevOps-Team"
  }
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg1"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location
  tags                = local.common_tags
}
```

### Data Source Chaining
```hcl
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "main" {
  name                = "my-key-vault"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.main.id
}
```

---

## 🛠️ Environment Setup

- **Cloud Provider**: Microsoft Azure
- **Terraform Version**: 1.8.x
- **Provider**: `hashicorp/azurerm` v3.0.0
- **Authentication**: Service Principal with Client Secret
- **Region**: East US

---

## 📁 Repository Structure

```
terraform-datasources/
│
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── terraform.tfvars       # Variable values (not in git)
├── .gitignore             # Git ignore file
└── README.md              # This documentation
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Azure subscription with appropriate permissions
- Terraform installed (v1.8+)
- Azure CLI configured
- Service Principal created

### 2. Clone and Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd terraform-datasources

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables with your values
nano terraform.tfvars
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply
```

### 4. Clean Up
```bash
# Destroy Terraform-managed resources
terraform destroy

# Manually clean up Azure Portal resources
# (Resource Group, VNet, Subnet)
```

---

## 🔗 Related Learning Topics

- **Terraform Locals** - Reusable variables and computed values
- **Terraform Provisioners** - Post-deployment configuration
- **Terraform Workspaces** - Environment management
- **Azure Resource Management** - RBAC and resource organization
- **Infrastructure as Code Best Practices** - Security and maintainability

---

## 📝 Notes & Lessons Learned

### 💡 Key Insights
- Data sources are **read-only** - they fetch information but don't modify resources
- Mixing manual and Terraform resources requires careful **state management**
- **Dependency management** becomes crucial in hybrid infrastructure setups
- **Error handling** and validation are essential for production deployments

### 🎓 Skills Developed
- Advanced Terraform data source usage
- Azure resource integration patterns
- Hybrid infrastructure management
- Security best practices for IaC
- Troubleshooting and debugging techniques

---

## 📎 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Service Principal Setup Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [Terraform Data Sources Official Guide](https://developer.hashicorp.com/terraform/language/data-sources)

---

**Next Module**: `locals` — Writing reusable logic and refactoring Terraform configurations for clarity and maintainability.
