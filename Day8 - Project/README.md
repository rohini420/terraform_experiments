# Terraform Workspaces

A comprehensive guide to using Terraform workspaces for managing multiple environments with isolated state.

## 🧠 What are Terraform Workspaces?

Imagine you're building **sandcastles on a beach**. You want to try different styles:
- One tall 🗼
- One wide 🏰  
- One with a moat 🌊

But you don't want them to mess with each other. So you pick **different corners of the beach**, label them ("dev", "prod"), and build separately.

Each labeled corner is like a **Terraform workspace**.

## 🧰 How Terraform Workspaces Work

- The **default** workspace is like your **main playground**
- When you create a **new workspace**, Terraform stores **state files separately**, so you can:
  - Deploy a dev environment in one workspace
  - A staging environment in another  
  - A production version in a third
  - All using the **same code**, but different **state**!

## 📁 Project Structure

```
terraform-workspaces/
├── .terraform/
├── terraform.tfstate.d/
│   ├── dev/
│   │   ├── terraform.tfstate
│   │   └── terraform.tfstate.backup
│   └── prod/
│       ├── terraform.tfstate
│       └── terraform.tfstate.backup
├── dev.tfvars
├── main.tf
├── prod.tfvars
└── variables.tf
```

## 💻 Essential Commands

### Creating Workspaces
```bash
# Create a new workspace
terraform workspace new dev
terraform workspace new prod
```

### Managing Workspaces
```bash
# List all workspaces
terraform workspace list

# Switch to a workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete a workspace (must be empty)
terraform workspace delete staging
```

### Deploying to Workspaces

#### For Development Environment:
```bash
# Switch to dev workspace
terraform workspace select dev

# Initialize (if first time)
terraform init

# Apply with dev-specific variables
terraform apply -var-file=dev.tfvars
```

#### For Production Environment:
```bash
# Switch to prod workspace  
terraform workspace select prod

# Apply with prod-specific variables
terraform apply -var-file=prod.tfvars
```

## 🎯 Workspace-Aware Configuration

You can reference the current workspace in your Terraform code:

```hcl
# main.tf
resource "azurerm_resource_group" "rg" {
    name     = "${var.rgname}"
    location = "${var.location}"
    tags      = {
        Environment = "Terraform Workspaces"
    }
}

## 📋 Variable Files by Environment

### dev.tfvars
```hcl
rgname = "Terraform-Dev"
location = "centralus"
```

### prod.tfvars  
```hcl
rgname = "Terraform-Prod"
location = "eastus"
```

## ✅ When to Use Workspaces

| **Use Case** | **Workspaces Ideal?** | **Notes** |
|--------------|----------------------|-----------|
| Different environments (dev/prod) | ✅ **Perfect** | Same infrastructure, different configurations |
| Different regions or accounts | ❌ **Not recommended** | Use separate directories or backend configs |
| Multiple teams/projects | ❌ **Not recommended** | Use different repos or state buckets |
| Testing infrastructure changes | ✅ **Good** | Create temporary workspace for testing |

## 🚨 Important Considerations

### State Isolation
- Each workspace maintains **completely separate state**
- Resources in different workspaces **cannot reference each other directly**
- State files are stored in `terraform.tfstate.d/<workspace-name>/`

### Backend Configuration
- All workspaces share the same backend configuration
- State files are organized by workspace name in the backend
- Remote backends (like Azure Storage) create separate state files per workspace

### Best Practices
1. **Always specify workspace** in your deployment scripts
2. **Use consistent naming conventions** across workspaces
3. **Document workspace purposes** and ownership
4. **Use variable files** for environment-specific configurations
5. **Test in dev workspace** before promoting to production

## 🔄 Typical Workflow

```bash
# 1. Create and switch to dev workspace
terraform workspace new dev

# 2. Initialize and plan
terraform init
terraform plan -var-file=dev.tfvars

# 3. Apply to dev
terraform apply -var-file=dev.tfvars

# 4. Test your changes in dev environment
# ... testing ...

# 5. Switch to production
terraform workspace select prod

# 6. Apply to production
terraform apply -var-file=prod.tfvars
```

## 🛠️ Troubleshooting

### Common Issues
- **Wrong workspace selected**: Always verify with `terraform workspace show`
- **State file conflicts**: Each workspace has isolated state - no conflicts possible
- **Resource naming**: Use `terraform.workspace` in resource names to avoid conflicts
- **Variable confusion**: Use separate `.tfvars` files for each environment

### Useful Commands for Debugging
```bash
# Check current workspace
terraform workspace show

# List all resources in current workspace
terraform state list

# Show state file location
terraform state pull
```

## 📚 Additional Resources

- [Terraform Workspaces Documentation](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Managing Multiple Environments](https://developer.hashicorp.com/terraform/intro/use-cases#multi-tier-applications)
- [State Management Best Practices](https://developer.hashicorp.com/terraform/language/state)

---

**Remember**: Workspaces are perfect for managing the same infrastructure across different environments, but consider other approaches for completely different projects or multi-tenant scenarios.