# Backend y proveedor para el sitio DR GCP/GKE (root module aislado).
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
  # Backend remoto azurerm: se configura con -backend-config=backend.hcl
  backend "azurerm" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
  # Credenciales: ADC vía `gcloud auth application-default login`
  # o GOOGLE_APPLICATION_CREDENTIALS en CI.
}
