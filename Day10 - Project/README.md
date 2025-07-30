# Terraform Multi-VM Azure Deployment

This project demonstrates deploying multiple Azure Linux Virtual Machines using Terraform's `count` function and built-in functions like `join()` and `lower()` for dynamic resource naming.

## 🏗️ Architecture Overview

The infrastructure creates:
- **1 Resource Group** - Logical container for all resources
- **1 Virtual Network** - Private network space (10.10.0.0/16)
- **2 Subnets** - Network segmentation using count
- **1 Storage Account** - For diagnostics and storage needs
- **2 Network Interfaces** - One per VM, mapped to respective subnets
- **2 Linux Virtual Machines** - Ubuntu 18.04-LTS instances

## 📁 Project Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Variable values (excluded from git)
├── outputs.tf           # Output definitions
└── README.md           # This file
```

## 🔧 Key Terraform Concepts Demonstrated

### 1. Count Function
Creates multiple resources with indexed naming:
```hcl
resource "azurerm_subnet" "subnet1" {
  count                = 2
  name                 = "subnet1-${count.index}"
  address_prefixes     = [var.subnet1_cidr_prefix[count.index]]
}
```

### 2. Terraform Functions
- **`join()`** - Concatenates strings for resource naming
- **`lower()`** - Ensures storage account names meet Azure requirements
- **`count.index`** - Creates unique identifiers for each resource instance

### 3. Resource Dependencies
Each VM is mapped to its own subnet and NIC:
```
VM[0] → NIC[0] → Subnet[0]
VM[1] → NIC[1] → Subnet[1]
```

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd terraform-multivm-azure
```

### 2. Configure Variables
Create a `terraform.tfvars` file:
```hcl
prefix = "myproject"
location = "eastus"
subnet1_cidr_prefix = ["10.10.1.0/24", "10.10.2.0/24"]
vnet_cidr_prefix = "10.10.0.0/16"
```

### 3. Set Azure Credentials
```bash
# Option 1: Azure CLI (Recommended)
az login

# Option 2: Environment Variables
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
```

### 4. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

## 📋 Resources Created

| Resource Type | Count | Naming Pattern | Purpose |
|---------------|-------|----------------|---------|
| Resource Group | 1 | `{prefix}rg01` | Container for all resources |
| Virtual Network | 1 | `{prefix}-10` | Private network space |
| Subnets | 2 | `subnet1-{0,1}` | Network segmentation |
| Storage Account | 1 | `{prefix}sa01` | Storage and diagnostics |
| Network Interfaces | 2 | `{prefix}-nic-{0,1}` | VM network connectivity |
| Linux VMs | 2 | `{prefix}-vmt01-{0,1}` | Ubuntu virtual machines |

## 🔐 Security Considerations

- **Credentials**: Never commit `terraform.tfvars` or any files containing secrets
- **VM Access**: Default configuration uses password authentication (not recommended for production)
- **Network Security**: Consider adding Network Security Groups (NSGs) for production deployments

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Storage Account Naming Error
```
Error: name can only consist of lowercase letters and numbers
```
**Solution**: Storage account names cannot contain dashes. The `lower()` function helps, but ensure your prefix doesn't contain special characters.

#### 2. Subnet CIDR Configuration
```
Error: subnet1_cidr_prefix[count.index] - Invalid index
```
**Solution**: Ensure `subnet1_cidr_prefix` is defined as a list in `terraform.tfvars`:
```hcl
subnet1_cidr_prefix = ["10.10.1.0/24", "10.10.2.0/24"]
```

#### 3. VM Resource Block Errors
For `azurerm_linux_virtual_machine`, use:
- `os_disk` instead of `storage_os_disk`
- `source_image_reference` instead of `storage_image_reference`
- Root-level `admin_username` and `admin_password` instead of `os_profile` blocks

## 📊 Outputs

After successful deployment, you'll see:
- Resource Group name
- Storage Account name
- VM names and IDs
- Network Interface IDs

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

## 🎯 Learning Outcomes

This project demonstrates:
- Using Terraform `count` for scaling resources
- Dynamic resource naming with Terraform functions
- Azure networking concepts (VNets, subnets, NICs)
- Infrastructure-as-Code best practices
- Resource dependency management

## 🤝 Contributing

Feel free to fork this repository and submit pull requests for improvements!

## 📄 License

This project is licensed under the MIT License.

## 🔗 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Terraform Count Meta-Argument](https://www.terraform.io/language/meta-arguments/count)

---

**Note**: This is a learning project. For production deployments, consider additional security measures, monitoring, and backup strategies.