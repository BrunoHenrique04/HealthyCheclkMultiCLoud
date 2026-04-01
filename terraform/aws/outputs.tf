output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.fiap_site_aws.public_ip
}

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.fiap_site_aws.id
}

output "ec2_security_group_id" {
  description = "ID do Security Group da EC2 (usado pelos comandos aws=up/down)"
  value       = aws_security_group.ec2_sg.id
}

output "site_url" {
  description = "URL do site via Route 53"
  value       = "http://rm${var.rm_number}.caserobots.com.br"
}

output "health_check_id" {
  description = "ID do Health Check do Route 53"
  value       = aws_route53_health_check.verificador.id
}
