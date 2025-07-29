# 🛠️ Terraform Provisioners Deep Dive

## 📘 Overview

This module focuses on **Terraform provisioners**—specialized tools that execute configuration tasks during resource creation. As an IT admin, provisioners help bridge the gap between infrastructure provisioning and application deployment, enabling automated post-creation configuration of virtual machines and other resources.

This learning module demonstrates three types of provisioners through separate implementations: **file**, **local-exec**, and **remote-exec**.

## 🎯 The IT Admin Challenge

### 🖥️ The Infrastructure Gap
As an IT admin, you often face this scenario: Terraform successfully creates your virtual machines, but they're essentially "empty shells." While the VM is running, it lacks:
- Required software packages
- Configuration files
- Application deployments
- Service configurations
- Custom scripts and tools

### 🔧 Enter Terraform Provisioners
Provisioners bridge this gap by allowing you to execute configuration tasks **during** the resource creation process. They enable you to:
- 📁 **Transfer files** from local to remote systems
- 💻 **Execute commands** on newly created VMs
- 📝 **Log information** to local systems
- ⚙️ **Automate post-deployment** configuration

## 🏗️ Base Infrastructure Components

All three implementations share the same foundational infrastructure:

### 🔍 Data Sources & Locals
```hcl
# Lookup existing resource group
data "azurerm_resource_group" "rg" {
  name = "terraform-rg"
}

locals {
  rg_info = data.azurerm_resource_group.rg
}

# Lookup existing VNet and Subnet
data "azurerm_virtual_network" "vnet1" {
  name                = "terraformVnet01"
  resource_group_name = local.rg_info.name
}

data "azurerm_subnet" "subnet1" {
  name                 = "subnet01"
  virtual_network_name = data.azurerm_virtual_network.vnet1.name
  resource_group_name  = local.rg_info.name
}
```

### 🔒 Network Security
```hcl
# Create NSG with SSH access
resource "azurerm_network_security_group" "nsg1" {
  name                = "terraform-nsg1"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location
}

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
```

### 🌐 Network Interface Setup
```hcl
# Static Public IP
resource "azurerm_public_ip" "pip1" {
  name                = "terraform-pip"
  resource_group_name = local.rg_info.name
  location            = local.rg_info.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface with Public IP
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
```

## 🧪 Provisioner Implementations

### 📁 Implementation 1: File Provisioner

**Purpose:** Upload local files to the newly created VM during deployment.

```hcl
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

  # File Provisioner - Upload script to VM
  provisioner "file" {
    source      = "./script.sh"
    destination = "/tmp/script.sh"
  }

  connection {
    type     = "ssh"
    host     = azurerm_public_ip.pip1.ip_address
    user     = "adminuser"
    password = "P@ssw0rd1234!"
    timeout  = "5m"
  }
}
```

**What it does:**
- Transfers `./script.sh` from local machine to `/tmp/script.sh` on the VM
- Requires SSH connection to the VM
- Useful for uploading configuration files, installation scripts, or certificates

### 💻 Implementation 2: Local-exec Provisioner

**Purpose:** Execute commands on the local machine where Terraform is running.

```hcl
resource "azurerm_linux_virtual_machine" "main" {
  # Same VM configuration as above...
  
  computer_name = "myvm"

  # Local-exec Provisioner - Save IP to local file
  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.pip1.ip_address} >> public_ip.txt"
  }
}
```

**What it does:**
- Executes on the **local machine** (not the VM)
- Saves the VM's public IP address to a local file `public_ip.txt`
- No connection block required
- Useful for logging, triggering external APIs, or updating local inventory files

### 🖥️ Implementation 3: Remote-exec Provisioner

**Purpose:** Connect to the VM and execute commands inside the remote system.

```hcl
resource "azurerm_linux_virtual_machine" "main" {
  # Same VM configuration...
  
  os_disk {
    name                 = "terraform-osdisk"  # Note: Different disk name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name = "myvm"

  # Remote-exec Provisioner - Execute commands on VM
  provisioner "remote-exec" {
    inline = [ 
      "ls -la /tmp",
    ]

    connection {
      type     = "ssh"
      host     = azurerm_public_ip.pip1.ip_address
      user     = self.admin_username
      password = self.admin_password
      timeout  = "5m" 
    }
  }
}
```

**What it does:**
- Connects to the VM via SSH
- Lists contents of `/tmp` directory
- Uses `self.admin_username` and `self.admin_password` references
- Executes commands **inside** the VM

## 🧹 Troubleshooting Journey

### ❌ Problem 1: SSH Connection Timeout
**Symptoms:** `timeout waiting for SSH connection`

**Root Causes:**
- NSG blocking SSH traffic (port 22)
- Public IP not assigned yet
- VM boot process not complete

**✅ Solution:**
```hcl
# Ensure NSG allows SSH
resource "azurerm_network_security_rule" "allow_ssh" {
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}
```

### ❌ Problem 2: Self Reference in Connection Block
**Issue:** Using `self.admin_username` vs direct username reference

**Your Implementation Approach:**
- **File provisioner:** Used direct strings in connection block
- **Remote-exec provisioner:** Used `self.admin_username` and `self.admin_password`

**Both approaches work, but have different use cases:**
```hcl
# Approach 1: Direct reference (file provisioner)
connection {
  user     = "adminuser"
  password = "P@ssw0rd1234!"
}

# Approach 2: Self reference (remote-exec provisioner)
connection {
  user     = self.admin_username
  password = self.admin_password
}
```

### ❌ Problem 3: Resource Naming Conflicts
**Issue:** Different OS disk names across implementations
- File provisioner: `"demo-osdisk"`
- Remote-exec provisioner: `"terraform-osdisk"`

**Solution:** Ensure unique resource names or use variables for consistency.

## 🧠 Key Learnings

### 📊 Provisioner Comparison

| Provisioner | Execution Location | Connection Required | Your Use Case |
|-------------|-------------------|-------------------|---------------|
| **file** | Local → Remote | Yes (SSH) | Upload `script.sh` to VM |
| **local-exec** | Local machine | No | Save public IP to local file |
| **remote-exec** | Remote VM | Yes (SSH) | List `/tmp` directory contents |

### 💡 Implementation Patterns

**Connection Block Variations:**
```hcl
# Static credentials (file provisioner)
connection {
  type     = "ssh"
  host     = azurerm_public_ip.pip1.ip_address
  user     = "adminuser"
  password = "P@ssw0rd1234!"
  timeout  = "5m"
}

# Self-referencing (remote-exec provisioner)
connection {
  type     = "ssh"
  host     = azurerm_public_ip.pip1.ip_address
  user     = self.admin_username
  password = self.admin_password
  timeout  = "5m"
}
```

**Local-exec Command Patterns:**
```hcl
# IP address logging
command = "echo ${azurerm_public_ip.pip1.ip_address} >> public_ip.txt"

# Resource ID logging (alternative)
command = "echo ${azurerm_public_ip.pip1.id} >> public_ip_id.txt"
```

## 📁 Project Structure

Based on your learning approach, you've organized this into three separate experiments:

```
DayX_Provisioners/
├── files/                    # File provisioner experiment
│   ├── main.tf              # VM with file provisioner
│   ├── script.sh            # Script to upload to VM
│   └── variables.tf         # Variable definitions
├── local-exec/              # Local execution experiment
│   ├── main.tf              # VM with local-exec provisioner
│   ├── public_ip.txt        # Generated by local-exec
│   └── variables.tf         # Variable definitions
├── remote-exec/             # Remote execution experiment
│   ├── main.tf              # VM with remote-exec provisioner
│   └── variables.tf         # Variable definitions
└── README.md                # This documentation
```

This structure allows you to:
- **Isolate each provisioner type** for focused learning
- **Compare implementations** side by side
- **Test individually** without interference
- **Maintain separate state files** for each experiment

## 🎯 Verification Steps

### 1. File Provisioner Verification
```bash
# SSH into the VM
ssh adminuser@<public_ip>

# Check if file was uploaded
ls -la /tmp/script.sh
cat /tmp/script.sh
```

### 2. Local-exec Verification
```bash
# Check local file created
cat public_ip.txt
```

### 3. Remote-exec Verification
```bash
# Check Terraform output for remote command results
terraform apply
# Look for the output of "ls -la /tmp" in the apply logs
```

## 🔐 Security Considerations

**⚠️ Current Configuration Issues:**
- Hardcoded credentials in provider block
- Password authentication instead of SSH keys
- Wide-open SSH access (`0.0.0.0/0`)
- Credentials stored in plain text

**🔒 Production Recommendations:**
```hcl
# Use environment variables
provider "azurerm" {
  features {}
  # Remove hardcoded credentials
  # Use: export ARM_CLIENT_ID="..."
  #      export ARM_CLIENT_SECRET="..."
  #      export ARM_SUBSCRIPTION_ID="..."
  #      export ARM_TENANT_ID="..."
}

# Restrict SSH access
source_address_prefix = "YOUR_IP/32"

# Use SSH keys
connection {
  type        = "ssh"
  host        = azurerm_public_ip.pip1.ip_address
  user        = "adminuser"
  private_key = file("~/.ssh/id_rsa")
}
```

## 💡 Best Practices Learned

1. **Separate concerns** - Use different provisioners for different tasks
2. **Test in isolation** - Separate configurations help identify issues
3. **Use locals** - Reference data sources through local values for cleaner code
4. **Secure connections** - Always use secure authentication methods
5. **Handle timeouts** - Set appropriate timeout values for network operations

## 🔗 Next Steps

**Upcoming Topics:**
- **Secrets Management** - Securing credentials with Azure Key Vault
- **Terraform Modules** - Creating reusable infrastructure components
- **State Management** - Remote state storage and locking
- **CI/CD Integration** - Automating Terraform deployments

## 📚 Additional Resources

- [Terraform Provisioners Documentation](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax)
- [Azure Linux VM Extensions](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/overview)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---
  
**Status:** ✅ Completed - All three provisioner types successfully implemented  
**Next:** Moving to terraform workspace practices
