# Root module DEV: instancia EXCLUSIVAMENTE el cluster cg-aks-dev.
module "aks" {
  source              = "../../modules/aks-cluster"
  environment         = "dev"
  location            = var.location
  resource_group_name = "rg-circle-guard-dev"
  cluster_name        = "cg-aks-dev"
  kubernetes_version  = "1.33"

  nodepools = [
    {
      name                = "default"
      vm_size             = "Standard_B2s"
      node_count          = 2
      min_count           = 1
      max_count           = 3
      enable_auto_scaling = false
      os_disk_type        = "Managed"
      os_disk_size_gb     = 128
    }
  ]

  create_acr = false
  tags       = var.tags
}
