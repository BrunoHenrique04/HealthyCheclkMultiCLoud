resource "aws_route53_health_check" "verificador" {
  ip_address        = aws_instance.fiap_site_aws.public_ip
  type              = "HTTP"
  port              = 80
  resource_path     = "/"
  request_interval  = 10
  failure_threshold = 3

  tags = {
    Name    = "verificador-rm${var.rm_number}"
    Managed = "terraform"
  }
}

resource "aws_route53_record" "registro_aws" {
  zone_id = var.hosted_zone_id
  name    = "rm${var.rm_number}"
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "registro-aws"
  health_check_id = aws_route53_health_check.verificador.id
  records         = [aws_instance.fiap_site_aws.public_ip]
}

resource "aws_route53_record" "registro_gcp" {
  zone_id = var.hosted_zone_id
  name    = "rm${var.rm_number}"
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "registro-gcp"
  records        = [var.gcp_site_ip]
}
