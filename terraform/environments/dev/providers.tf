# Backend y proveedor para el entorno DEV (root module aislado)
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  # Backend remoto: se configura con -backend-config=backend.hcl en terraform init
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  # subscription_id se toma de ARM_SUBSCRIPTION_ID
}
