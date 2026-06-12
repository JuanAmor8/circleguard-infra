output "aks_name" {
  description = "Nombre del cluster AKS PROD"
  value       = module.aks.aks_name
}

output "resource_group_name" {
  description = "Resource Group del cluster PROD"
  value       = module.aks.resource_group_name
}

output "aks_fqdn" {
  description = "FQDN del API server PROD"
  value       = module.aks.aks_fqdn
}

output "acr_login_server" {
  description = "Login server del ACR PROD"
  value       = module.aks.acr_login_server
}

output "acr_name" {
  description = "Nombre del ACR PROD"
  value       = module.aks.acr_name
}

output "kube_config_raw" {
  description = "Kubeconfig del cluster PROD (base64). Usar para KUBE_CONFIG_PROD."
  value       = module.aks.kube_config_raw
  sensitive   = true
}
