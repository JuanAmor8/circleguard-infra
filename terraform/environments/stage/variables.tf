variable "location" {
  description = "Región de Azure para el entorno STAGE"
  type        = string
  default     = "centralus"
}

variable "tags" {
  description = "Tags aplicados a todos los recursos STAGE"
  type        = map(string)
  default = {
    Project     = "CircleGuard"
    Environment = "stage"
    ManagedBy   = "Terraform"
  }
}
