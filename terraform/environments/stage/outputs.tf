output "aks_name" {
  description = "Nombre del cluster AKS STAGE"
  value       = module.aks.aks_name
}

output "resource_group_name" {
  description = "Resource Group del cluster STAGE"
  value       = module.aks.resource_group_name
}

output "aks_fqdn" {
  description = "FQDN del API server STAGE"
  value       = module.aks.aks_fqdn
}

output "kube_config_raw" {
  description = "Kubeconfig del cluster STAGE (base64). Usar para KUBE_CONFIG_STAGE."
  value       = module.aks.kube_config_raw
  sensitive   = true
}
