output "aks_name" {
  description = "Nombre del cluster AKS DEV"
  value       = module.aks.aks_name
}

output "resource_group_name" {
  description = "Resource Group del cluster DEV"
  value       = module.aks.resource_group_name
}

output "aks_fqdn" {
  description = "FQDN del API server DEV"
  value       = module.aks.aks_fqdn
}

output "kube_config_raw" {
  description = "Kubeconfig del cluster DEV (base64). Usar para KUBE_CONFIG_DEV."
  value       = module.aks.kube_config_raw
  sensitive   = true
}
