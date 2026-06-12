# Backend y proveedor para el entorno STAGE (root module aislado)
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
