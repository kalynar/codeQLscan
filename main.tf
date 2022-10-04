terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.7.0"
    }
  }


  backend "azurerm" {
    resource_group_name  = "kalyna-tf"
    storage_account_name = "kalynatfbackend"
    container_name       = "kalynastatecontainer"
    key                  = "uat.terraform.tfstate"
    use_msi              = true
    subscription_id      = "04b23413-3fdf-4a5c-bfce-16534db0213a"
    tenant_id            = "e85feadf-11e7-47bb-a160-43b98dcc96f1"
  }


  required_version = ">= 1.1.0"
}

data "external" "current_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "terraform-iac"
  location = "eastus2"
}

resource "azurerm_key_vault" "kv" {
  name                = "kalynakeyvault2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  purge_protection_enabled = true

  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    #ip_rules = ["${data.external.current_ip.result.ip}"]
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnetiac"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet" {
  name                 = "snetiac"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.16/28"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_storage_account" "storage" {
  name                     = "examplesa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
