variable "project_id" {
  description = "Proyecto de GCP donde se crea el sitio DR"
  type        = string
}

variable "region" {
  description = "Zona/región de GCP (zonal: us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

variable "tags" {
  description = "Labels para los recursos GCP"
  type        = map(string)
  default = {
    project     = "circleguard"
    environment = "dr"
    managedby   = "terraform"
  }
}
