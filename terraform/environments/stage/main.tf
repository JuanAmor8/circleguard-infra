# Root module STAGE: instancia EXCLUSIVAMENTE el cluster cg-aks-stage.
module "aks" {
  source              = "../../modules/aks-cluster"
  environment         = "stage"
  location            = var.location
  resource_group_name = "rg-circle-guard-stage"
  cluster_name        = "cg-aks-stage"
  kubernetes_version  = "1.33"

  nodepools = [
    {
      name                = "default"
      vm_size             = "Standard_B2ms"
      node_count          = 3
      min_count           = 3
      max_count           = 6
      enable_auto_scaling = true
      os_disk_type        = "Managed"
      os_disk_size_gb     = 128
    },
    {
      # FinOps: capacidad de ráfaga en nodos Spot (hasta -90% de costo).
      # min 0 = scale-to-zero cuando no hay carga; las cargas que corren aquí
      # toleran evicción (taint scalesetpriority=spot:NoSchedule).
      name                = "burst"
      vm_size             = "Standard_B2ms"
      node_count          = 0
      min_count           = 0
      max_count           = 3
      enable_auto_scaling = true
      priority            = "Spot"
      eviction_policy     = "Delete"
      spot_max_price      = -1
      os_disk_type        = "Managed"
      os_disk_size_gb     = 128
    }
  ]

  create_acr = false
  tags       = var.tags
}
