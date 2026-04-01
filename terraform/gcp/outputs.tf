output "gcp_instance_external_ip" {
  description = "IP externo da VM GCP — use como var.gcp_site_ip no módulo AWS"
  value       = google_compute_instance.fiap_site_gcp.network_interface[0].access_config[0].nat_ip
}

output "gcp_instance_name" {
  description = "Nome da instância GCP"
  value       = google_compute_instance.fiap_site_gcp.name
}

output "gcp_firewall_name" {
  description = "Nome da regra de firewall (usado por google=up/down)"
  value       = google_compute_firewall.allow_http.name
}
