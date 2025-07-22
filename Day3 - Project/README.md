# Terraform State Management & Import Experiment

## 🎯 Project Overview

This experiment demonstrates critical Terraform concepts including statefile management, resource import, and recovery from accidental state deletion. The project provisions Azure infrastructure using Terraform variables and showcases how to handle state restoration when files are accidentally deleted.

## 🏗️ Infrastructure Components

The Terraform configuration deploys the following Azure resources:

- **Resource Group**: `terraform_rg1`
- **Virtual Network**: `terraform_pratice-10`
- **Subnet**: `subnet01`
- **Network Security Group**: `terraform_pratice-nsg1`
- **Network Security Rule**: RDP access rule
- **Network Interface**: `terraform_pratice-nic`
- **Windows Virtual Machine**: `terraform_pratice.vmt01`
- **NSG-Subnet Association**: Links security group to subnet

## 📁 Project Structure

```
azure_terraform_experiment/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars          # Variable values (optional)
├── .terraform.lock.hcl        # Provider version lock file
├── terraform.tfstate          # Current state file
├── terraform.tfstate.backup   # Backup state file
└── .terraform/                # Provider plugins directory
```

## 🔧 Variables Configuration

The project uses variables for better maintainability and reusability:

```hcl
variable "location" {
  default = "eastus"
}

variable "resource_group_name" {
  default = "terraform_rg1"
}

variable "vnet_name" {
  default = "terraform_pratice-10"
}
```

## 🧪 Experiment Objectives

### Primary Learning Goals:
1. **Variable-based Terraform design** - Clean separation of configuration and data
2. **State file management** - Understanding terraform.tfstate importance
3. **State restoration techniques** - Recovery from accidental deletions
4. **Terraform import command** - Bringing existing resources under management
5. **Lock file handling** - Managing provider dependencies

## ⚠️ The Problem: Accidental State Deletion

During the experiment, the following critical files were accidentally deleted:
- `.terraform.lock.hcl`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.terraform/` directory

### Impact:
- Lost provider references
- Lost infrastructure state tracking
- Terraform attempted to recreate existing resources
- Error: "A resource with the ID ... already exists"

## 🔄 Recovery Process

### Step 1: Reinitialize Terraform
```bash
terraform init
```
This command:
- ✅ Re-downloaded provider plugins
- ✅ Re-created `.terraform.lock.hcl`
- ✅ Restored `.terraform/` directory

### Step 2: Manual State Import

Each existing Azure resource was manually imported using their Azure resource IDs:

```bash
# Import Resource Group
terraform import azurerm_resource_group.rg /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1

# Import Virtual Network
terraform import azurerm_virtual_network.vnet1 /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/virtualNetworks/terraform_pratice-10

# Import Subnet
terraform import azurerm_subnet.subnet1 /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/virtualNetworks/terraform_pratice-10/subnets/subnet01

# Import Network Interface
terraform import azurerm_network_interface.nic1 /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/networkInterfaces/terraform_pratice-nic

# Import Network Security Group
terraform import azurerm_network_security_group.nsg1 /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/networkSecurityGroups/terraform_pratice-nsg1

# Import Virtual Machine
terraform import azurerm_windows_virtual_machine.main /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Compute/virtualMachines/terraform_pratice.vmt01

# Import Network Security Rule
terraform import azurerm_network_security_rule.rdp /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/networkSecurityGroups/terraform_pratice-nsg1/securityRules/rdp

# Import NSG-Subnet Association
terraform import azurerm_subnet_network_security_group_association.nsg_subnet_assoc /subscriptions/<Azure Subscription ID>/resourceGroups/terraform_rg1/providers/Microsoft.Network/virtualNetworks/terraform_pratice-10/subnets/subnet01
```

### Step 3: Verification
```bash
terraform plan
```
**Result**: "No changes. Your infrastructure matches the configuration."

```bash
terraform apply
```
**Result**: "Apply complete! Resources: 0 added, 0 changed, 0 destroyed."

## 📚 Key Learnings

### State File Importance
- **terraform.tfstate** tracks infrastructure metadata and resource relationships
- Enables idempotency - prevents duplicate resource creation
- Essential for Terraform to understand current infrastructure state

### Recovery Best Practices
1. **Never delete state files** unless intentionally starting over
2. **Always run `terraform plan`** before `terraform apply`
3. **Use `terraform import`** to bring existing resources under management
4. **Backup state files** regularly
5. **Use remote backend** for production environments

### Import Strategy
1. Identify existing resources in Azure Portal
2. Find resource IDs from Azure Portal or CLI
3. Use Terraform documentation for correct import syntax
4. Import resources one by one
5. Verify with `terraform plan`

## 🛡️ Prevention Strategies

### Remote Backend Configuration
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "terraformbackendsa"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### Version Control Best Practices
- Add `terraform.tfstate*` to `.gitignore`
- Commit `.terraform.lock.hcl` to version control
- Never commit state files to public repositories

## 🔗 Useful Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Import Documentation](https://www.terraform.io/docs/import/index.html)
- [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

## 📝 Notes

This experiment successfully demonstrated the critical importance of Terraform state management and provided hands-on experience with disaster recovery scenarios. The manual import process, while tedious, ensures complete understanding of resource relationships and dependencies.

---

**⚡ Pro Tip**: Always use `terraform import` reference documentation from the official Terraform registry. Search for "terraform [resource_name]" and navigate to the "Import" section for correct syntax.
