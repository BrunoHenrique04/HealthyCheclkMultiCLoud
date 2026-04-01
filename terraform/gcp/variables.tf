variable "gcp_project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "gcp_region" {
  description = "Região GCP"
  type        = string
  default     = "us-east1"
}

variable "gcp_zone" {
  description = "Zona GCP"
  type        = string
  default     = "us-east1-b"
}

variable "rm_number" {
  description = "Número de RM do aluno"
  type        = string
}
