terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
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

resource "azurerm_resource_group" "rg" {
  name     = join("", [var.prefix, "rg01"])
  location = "EastUS"
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

output "rgname" {
    value = azurerm_resource_group.rg.name
  
}

output "saname" {
    value = azurerm_storage_account.sa.name
  
}

