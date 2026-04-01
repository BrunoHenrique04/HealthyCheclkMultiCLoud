terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_compute_firewall" "allow_http" {
  name    = "fiap-allow-http-rm${var.rm_number}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["fiap-web-rm${var.rm_number}"]

  description = "Permite trafego HTTP na porta 80 — controlado pelos comandos google=up/down"
}

resource "google_compute_instance" "fiap_site_gcp" {
  name         = "fiap-site-rm${var.rm_number}"
  machine_type = "e2-micro"
  zone         = var.gcp_zone

  tags = ["fiap-web-rm${var.rm_number}"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo '<html><body style="font-family:Arial;background:#fff0f0;text-align:center;padding:60px">
      <h1 style="color:#4285F4">FIAP Multicloud</h1>
      <h2 style="color:#EA4335">ATENCAO: Servidor GCP Ativo!</h2>
      <p>A AWS caiu. O Google Cloud assumiu o controle.</p>
    </body></html>' > /var/www/html/index.html
  EOF

  labels = {
    lab     = "fiap-multicloud"
    aluno   = "rm${var.rm_number}"
    managed = "terraform"
  }
}
