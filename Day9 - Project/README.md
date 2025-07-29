# Terraform Azure Resource Group & Storage Account Deployment using terraform functions

This project provisions an **Azure Resource Group** and a **Storage Account** using Terraform. The resource names are dynamically generated using Terraform functions like `join()` and `lower()`.

---

## 📁 Project Structure

```bash
.
├── main.tf
├── variables.tf
├── terraform.tfvars
├── .gitignore
└── README.md
```

## 🔧 What This Does

* Creates a **Resource Group** named `terraformftnRG01`
* Creates a **Storage Account** named `terraformftnsa01`
* Tags the storage account with environment = "staging"
* Demonstrates use of `join()` and `lower()` functions to construct dynamic names

## 📦 Terraform Files

### main.tf
Defines resources:

```hcl
resource "azurerm_resource_group" "rg" {
  name     = join("", [var.prefix, "RG01"])
  location = var.location
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
```

### 📥 Inputs (variables.tf)

```hcl
variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}
```



## 🔒 Security Setup

### 1. Set your variable values
You can set variables in multiple ways:

**Option A: Command line**
```bash
terraform apply -var="location=eastus" -var="prefix=terraformftn"
```

**Option B: Create terraform.tfvars file (keep it secret)**
```hcl
location = "eastus"
prefix = "terraformftn"
```

### 2. Authentication Methods

**Option A: Environment Variables (Recommended)**
```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

**Option B: Azure CLI**
```bash
az login
az account set --subscription "your-subscription-id"
```

### 3. .gitignore Configuration

Create a `.gitignore` file with:

```gitignore
# Terraform files
*.tfstate
*.tfstate.*
*.tfstate.backup
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log

# Sensitive files - NEVER COMMIT THESE
terraform.tfvars
*.auto.tfvars
*.auto.tfvars.json

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Environment files
.env
.env.local
.env.*.local

# Backup files
*.bak
*~
```

## 🚀 Usage

1. **Initialize** the backend and providers:
```bash
terraform init
```

2. **Preview** the changes:
```bash
terraform plan
```

3. **Apply** the configuration:
```bash
terraform apply
```

4. **Destroy** the resources (when needed):
```bash
terraform destroy
```

## 🛡️ Security Best Practices

### ⚠️ CRITICAL: Never Commit These Files
- `terraform.tfvars` (contains sensitive values)
- `*.tfstate` files (may contain secrets in plain text)
- Any files with credentials or API keys

### ✅ Safe Files to Commit
- `*.tf` files (infrastructure code)
- `README.md` and documentation

### 🔐 Secret Management Options
1. **Environment Variables**: Set `ARM_*` variables in your shell
2. **Azure Key Vault**: Store secrets in Key Vault and reference them
3. **CI/CD Secrets**: Use GitHub Secrets, Azure DevOps Variable Groups, etc.
4. **Terraform Cloud/Enterprise**: Built-in sensitive variable management

## 📝 Notes

* Storage account names must be **globally unique**, all lowercase, and between 3–24 characters
* Resource group names can be more flexible but must avoid invalid characters
* Always run `terraform plan` before `terraform apply` to review changes
* Use remote state storage for team collaboration

## 🧹 Cleanup & Maintenance

* Run `terraform destroy` to clean up resources when no longer needed
* Regularly update Terraform and provider versions
* Review and rotate access credentials periodically

---

**General Resources**
- [All Terraform Functions](https://developer.hashicorp.com/terraform/language/functions)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Terraform Best Practices](https://docs.microsoft.com/en-us/azure/developer/terraform/best-practices)
- [Terraform Security Best Practices](https://learn.hashicorp.com/tutorials/terraform/security-best-practices)
