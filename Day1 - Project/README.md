# Terraform Azure Infrastructure Setup

This repository contains Terraform configuration files for provisioning Azure infrastructure including Resource Groups, Virtual Networks, and Subnets.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Azure Service Principal Setup](#azure-service-principal-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Resources Created](#resources-created)
- [Troubleshooting](#troubleshooting)
- [Clean Up](#clean-up)

## 🔧 Prerequisites

- **Terraform** >= v1.6.0
- **Azure CLI** (optional, for authentication)
- **Azure Subscription** (Azure for Students or regular subscription)
- **Git** (for version control)

## 🚀 Installation

### Installing Terraform with tfenv (Recommended)

```bash
# Install tfenv (Terraform version manager)
brew install tfenv

# Install latest Terraform version
tfenv install latest
tfenv use latest

# Verify installation
terraform -version
```

### Alternative: Direct Homebrew Installation

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## 🔐 Azure Service Principal Setup

### Step 1: Create App Registration

1. Log into [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Click **New registration**
4. Fill in application details and click **Register**

### Step 2: Get Required IDs

After registration, note down:
- **Application (client) ID**: `your-client-id-here`
- **Directory (tenant) ID**: `your-tenant-id-here`

### Step 3: Create Client Secret

1. Go to **Certificates & secrets**
2. Click **New client secret**
3. Add description and expiration
4. **Copy the secret value immediately**: `your-client-secret-here`

### Step 4: Get Subscription ID

1. Navigate to **Subscriptions** in Azure Portal
2. Copy your **Subscription ID**: `your-subscription-id-here`

### Step 5: Assign Contributor Role

1. Go to **Subscriptions** > Your subscription
2. Click **Access control (IAM)** > **Role assignments**
3. Click **Add** > **Add role assignment**
4. Select **Contributor** role
5. Search and select your created application
6. Click **Review + assign**

## 🔐 Environment Variables (Recommended)

For better security, use environment variables instead of hardcoding credentials:

```bash
export ARM_CLIENT_ID="your-client-id-here"
export ARM_CLIENT_SECRET="your-client-secret-here"
export ARM_SUBSCRIPTION_ID="your-subscription-id-here"
export ARM_TENANT_ID="your-tenant-id-here"
```

Then simplify your provider configuration:

```hcl
provider "azurerm" {
  features {}
  # Credentials will be read from environment variables
}
```

## ⚙️ Configuration

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

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  
  subscription_id = "your-subscription-id-here"
  client_id       = "your-client-id-here"
  tenant_id       = "your-tenant-id-here"
  client_secret   = "your-client-secret-here"
}

# Resource Group
resource "azurerm_resource_group" "rg1" {
  location = "East US"
  name     = "terraform_rg1"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet1" {
  name                = "terraform_vnet1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.10.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "terraform_subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.10.1.0/24"]
}
```

## 🏃‍♂️ Usage

### 1. Initialize Terraform

```bash
mkdir azure_example
cd azure_example

# Initialize Terraform (downloads required providers)
terraform init
```

### 2. Validate Configuration

```bash
# Check syntax and validate configuration
terraform validate
```

### 3. Plan Infrastructure

```bash
# Preview what resources will be created
terraform plan
```

### 4. Apply Configuration

```bash
# Create the infrastructure
terraform apply

# Type 'yes' when prompted
```

### 5. Verify Resources

Check the [Azure Portal](https://portal.azure.com) to confirm:
- Resource Group: `terraform_rg1`
- Virtual Network: `terraform_vnet1`
- Subnet: `terraform_subnet1`

## 📦 Resources Created

| Resource Type | Name | Configuration |
|---------------|------|---------------|
| **Resource Group** | `terraform_rg1` | Location: East US |
| **Virtual Network** | `terraform_vnet1` | Address Space: 10.10.0.0/16 |
| **Subnet** | `terraform_subnet1` | Address Prefix: 10.10.1.0/24 |

## 🔍 Terraform Commands Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `terraform init` | Initialize project and download providers | First time setup |
| `terraform validate` | Check syntax and configuration | Before planning |
| `terraform plan` | Preview changes | Before applying |
| `terraform apply` | Create/update resources | Deploy infrastructure |
| `terraform destroy` | Delete all resources | Clean up |

## 🐛 Troubleshooting

### Common Issues

#### 1. "Insufficient privileges" Error
**Solution**: Ensure your Service Principal has **Contributor** role on the subscription.

#### 2. "Provider not found" Error
**Solution**: Run `terraform init` to download required providers.

#### 3. "Invalid authentication" Error
**Solution**: Verify your Service Principal credentials in the provider block.

#### 4. Old Terraform Version
**Solution**: Use `tfenv` to install the latest version (>= 1.6.0).

### Dependency Order

Terraform automatically handles resource dependencies:
```
Resource Group → Virtual Network → Subnet
```

## 🧹 Clean Up

To destroy all created resources:

```bash
# This will delete ALL resources managed by Terraform
terraform destroy

# Type 'yes' when prompted
```

⚠️ **Warning**: This action is irreversible!

## 🔗 Useful Links

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Microsoft Learn - Terraform with Azure](https://learn.microsoft.com/en-us/training/modules/deploy-java-azure-pipeline-terraform/1-introduction)
- [Azure Portal](https://portal.azure.com)

## 📝 Notes

- Keep your Service Principal credentials secure
- Consider using Azure Key Vault for production environments
- The `terraform.tfstate` file contains sensitive information - never commit to version control
- Use `.gitignore` to exclude sensitive files:

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
*.tfvars
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.