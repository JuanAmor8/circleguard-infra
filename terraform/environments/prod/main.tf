# Root module PROD: instancia EXCLUSIVAMENTE el cluster cg-aks-prod.
module "aks" {
  source              = "../../modules/aks-cluster"
  environment         = "prod"
  location            = var.location
  resource_group_name = "rg-circle-guard-prod"
  cluster_name        = "cg-aks-prod"
  kubernetes_version  = "1.33"

  nodepools = [
    {
      # System pool SIEMPRE on-demand: alojar el plano de sistema en Spot
      # arriesga evicciones de CoreDNS/metrics; el ahorro Spot va en pools
      # de usuario tolerantes (ver pool burst de stage).
      name                = "system"
      vm_size             = "Standard_B4ms"
      node_count          = 3
      min_count           = 3
      max_count           = 5
      enable_auto_scaling = true
      os_disk_type        = "Managed"
      os_disk_size_gb     = 128
    },
    {
      name                = "user"
      vm_size             = "Standard_B2ms"
      node_count          = 5
      min_count           = 5
      max_count           = 10
      enable_auto_scaling = true
      os_disk_type        = "Managed"
      os_disk_size_gb     = 128
    }
  ]

  create_acr = true
  tags       = var.tags
}
