variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "rm_number" {
  description = "Número de RM do aluno (ex: 562192)"
  type        = string
}

variable "hosted_zone_id" {
  description = "ID da Hosted Zone do Route 53 (caserobots.com.br)"
  type        = string
}

variable "gcp_site_ip" {
  description = "IP externo da VM do GCP (preenchido após o deploy GCP)"
  type        = string
  default     = ""
}

variable "aws_public_key" {
  description = "Chave pública SSH (conteúdo) para criar Key Pair na AWS. Opcional."
  type        = string
  default     = ""
}
