# Terraform Multi-Environment Azure Infrastructure

A comprehensive Infrastructure as Code (IaC) project demonstrating modular Terraform deployments across multiple Azure environments (Dev, UAT, Prod) with remote state management.

## 🏗️ Architecture Overview

This project provisions three isolated Azure environments using a single reusable Terraform module:

- **Development Environment** (DevRG)
- **UAT Environment** (UATRG) 
- **Production Environment** (ProdRG)

Each environment includes:
- Resource Group
- Virtual Network (VNet) with custom CIDR blocks
- Subnet configuration
- Network Security Group (NSG) with RDP rules
- Network Interface (NIC)
- Windows Virtual Machine

## 📁 Project Structure

```
azure_example/
├── main.tf                 # Azure provider configuration
├── backend.tf              # Remote state backend configuration
├── variables.tf            # Root-level variable declarations
├── terraform.tfvars        # Sensitive values (excluded from Git)
├── dev.tf                  # Development environment module call
├── uat.tf                  # UAT environment module call
├── prod.tf                 # Production environment module call
├── modules/
│   ├── main.tf             # Reusable infrastructure resources
│   └── variables.tf        # Module input variables
└── README.md
```

## 🚀 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions
- Azure Service Principal (for authentication)

## ⚙️ Setup Instructions

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd azure_example
```

### 2. Create Azure Service Principal
```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"
```

### 3. Set Up Remote State Storage
```bash
# Create resource group for Terraform state
az group create --name terraform-rg --location eastus

# Create storage account
az storage account create \
  --name tfstorage2025 \
  --resource-group terraform-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false

# Create container for state file
az storage container create \
  --name tfstatecontainer \
  --account-name tfstorage2025
```

### 4. Configure Authentication

Create `terraform.tfvars` file (excluded from Git):
```hcl
subscription_id = "your-subscription-id"
client_id       = "your-client-id"
tenant_id       = "your-tenant-id"
client_secret   = "your-client-secret"
```

**Alternative: Environment Variables**
```bash
export TF_VAR_subscription_id="your-subscription-id"
export TF_VAR_client_id="your-client-id"
export TF_VAR_tenant_id="your-tenant-id"
export TF_VAR_client_secret="your-client-secret"
```

## 🔧 Usage

### Initialize Terraform
```bash
terraform init -reconfigure
```

### Plan Deployment
```bash
terraform plan -out=tfplan
terraform show tfplan  # Review the plan
```

### Apply Changes
```bash
terraform apply tfplan
```

### Destroy Infrastructure
```bash
terraform destroy
```

## 🌍 Environment Configuration

### Development Environment
- **Resource Group**: DevRG
- **VNet CIDR**: 10.20.0.0/16
- **Subnet CIDR**: 10.20.1.0/24
- **Prefix**: dev

### UAT Environment
- **Resource Group**: UATRG
- **VNet CIDR**: 10.30.0.0/16
- **Subnet CIDR**: 10.30.1.0/24
- **Prefix**: uat

### Production Environment
- **Resource Group**: ProdRG
- **VNet CIDR**: 10.40.0.0/16
- **Subnet CIDR**: 10.40.1.0/24
- **Prefix**: prod

## 🔒 Security Features

- **Remote State Locking**: Prevents concurrent modifications using Azure Blob lease mechanism
- **Private Storage**: Blob public access disabled
- **Environment Isolation**: Separate resource groups and network ranges
- **NSG Rules**: Configurable RDP access (currently set to Deny)

## 🚨 Common Issues & Solutions

### 1. Duplicate Required Providers Error
**Error**: `Duplicate required providers configuration`

**Solution**: Remove `required_providers` block from modules, keep only in root `backend.tf`

### 2. Resource Already Exists Error
**Error**: `A resource with the ID already exists`

**Solution**: Import existing resource into Terraform state:
```bash
terraform import <resource_address> <resource_id>
```

### 3. Authentication Failed (403)
**Error**: `403: AuthenticationFailed`

**Solution**: Ensure proper Azure AD roles (Storage Blob Data Contributor) are assigned

### 4. State Lock Error
**Error**: `Error acquiring the state lock`

**Solution**: 
- Wait for other operations to complete, or
- Force unlock (emergency only): `terraform force-unlock <LOCK_ID>`

## 🔄 State Management

### Remote Backend Configuration
The project uses Azure Blob Storage for remote state management:
- **Storage Account**: tfstorage2025
- **Container**: tfstatecontainer
- **State File**: terraform.tfstate

### State Operations
```bash
# View current state
terraform state list

# Pull state backup
terraform state pull > backup.tfstate

# Import existing resource
terraform import <address> <id>
```

## 🧪 Testing Multi-Machine Collaboration

To simulate team collaboration:

1. Create two project directories
2. Copy configuration files to both
3. Initialize both with same backend
4. Make changes in one directory
5. Observe state synchronization in the other

## 📝 Module Structure

The reusable module (`./modules`) creates:
- Azure Resource Group
- Virtual Network with subnet
- Network Security Group with RDP rule
- Network Interface
- Windows Virtual Machine

### Module Variables
- `rgname`: Resource group name
- `location`: Azure region (default: eastus)
- `prefix`: Resource naming prefix
- `vnet_cidr_prefix`: VNet address space
- `subnet1_cidr_prefix`: Subnet address space
- `subnet1`: Subnet name

## 🎯 Key Learnings

- **Remote State is Essential**: Enables team collaboration and prevents state drift
- **Modules Enable Scalability**: Write once, deploy everywhere principle
- **State Locking Prevents Conflicts**: Azure Blob lease mechanism ensures safe concurrent operations
- **Import Before Recreate**: Always import existing resources rather than destroying/recreating
- **Error-Driven Learning**: Each error teaches valuable lessons about Terraform internals

## 🔧 Maintenance

### Update Terraform Providers
```bash
terraform init -upgrade
```

### Format Code
```bash
terraform fmt -recursive
```

### Validate Configuration
```bash
terraform validate
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Module Best Practices](https://www.terraform.io/docs/modules/index.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: Always review `terraform plan` output before applying changes to production environments. Keep sensitive information like `terraform.tfvars` out of version control.