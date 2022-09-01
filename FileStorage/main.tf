terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.93.0"
    }
  }
}

provider "azurerm" {
    subscription_id = "3d0e9868-07c1-46ce-be62-902533cf6509"
    client_id = "5663c2c1-cdea-48bc-8bfe-6f75a394f922"
    client_secret = "cGH8Q~qH2oJYNqtmP2rjTFI~f7FnbvYwrg5gTbwt"
    tenant_id = "01454e03-3623-4535-b171-d8a0cf6d8eff"
    skip_provider_registration = true
    features {
      
    }
}




resource "azurerm_storage_account" "filestorage4" {
  name                     = "filestorage4"
  resource_group_name      = "myResGroup"
  location                 = "Central US"
  account_tier             = "Standard"
  account_replication_type = "LRS"

}