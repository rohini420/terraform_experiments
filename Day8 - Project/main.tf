terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
provider "azurerm" {
  features {} 
  subscription_id  = "your-subscription-id-here"
  client_id = "your-client-id-here"
  tenant_id = "your-tenant-id-here"
  client_secret = "your-client-secret-here"
}

#create resource group
resource "azurerm_resource_group" "rg" {
    name     = "${var.rgname}"
    location = "${var.location}"
    tags      = {
        Environment = "Terraform Workspaces"
    }
}