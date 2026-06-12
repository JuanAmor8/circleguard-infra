variable "location" {
  description = "Región de Azure para el entorno DEV"
  type        = string
  default     = "centralus"
}

variable "tags" {
  description = "Tags aplicados a todos los recursos DEV"
  type        = map(string)
  default = {
    Project     = "CircleGuard"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
