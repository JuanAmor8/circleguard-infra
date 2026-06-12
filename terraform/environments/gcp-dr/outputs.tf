output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value     = module.gke.endpoint
  sensitive = true
}

output "velero_bucket" {
  value = google_storage_bucket.velero_dr.name
}

output "velero_sa_email" {
  value = google_service_account.velero.email
}

output "velero_sa_key_base64" {
  description = "Clave de la SA de Velero (base64). Decodificar a gcp-velero-sa.json."
  value       = google_service_account_key.velero.private_key
  sensitive   = true
}
