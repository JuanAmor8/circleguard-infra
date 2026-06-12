variable "location" {
  description = "Región de Azure para el entorno PROD"
  type        = string
  default     = "centralus"
}

variable "tags" {
  description = "Tags aplicados a todos los recursos PROD"
  type        = map(string)
  default = {
    Project     = "CircleGuard"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
