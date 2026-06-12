# Sitio DR GCP/GKE: cluster zonal spot (espejo del cg-aks-dev) + bucket GCS
# y service account para el respaldo cruzado con Velero (AKS -> GCS).

module "gke" {
  source             = "../../modules/gke-cluster"
  environment        = "dr"
  project_id         = var.project_id
  region             = var.region # zona us-central1-a -> cluster zonal
  cluster_name       = "cg-gke-dr"
  kubernetes_version = "1.29"

  nodepools = [
    {
      name                = "default"
      machine_type        = "e2-medium" # shared-core: ~940m allocatable/nodo
      node_count          = 2
      min_count           = 1
      max_count           = 5 # 13 pods no caben en 3 nodos shared-core
      enable_auto_scaling = true
      disk_size_gb        = 50
      spot                = true # FinOps: spot GCP (~ -80/91%)
    }
  ]

  tags = var.tags
}

# --- Velero: bucket de respaldo cruzado (vive en GCP, respalda AKS) ---
resource "google_storage_bucket" "velero_dr" {
  name                        = "cg-velero-dr-${var.project_id}"
  project                     = var.project_id
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true # solo demo; quitar en prod real
  labels                      = var.tags
}

resource "google_service_account" "velero" {
  account_id   = "velero-backup"
  display_name = "Velero cross-cloud backup"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "velero" {
  bucket = google_storage_bucket.velero_dr.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_key" "velero" {
  service_account_id = google_service_account.velero.name
}
