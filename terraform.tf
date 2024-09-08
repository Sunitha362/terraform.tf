
provider "google" {
    credentials = file("<path-to-your-service-account-key>")
    project     = "<your-gcp-project-id>"
    region      = "us-central1"
}

resource "google_compute_network" "vpc_network" {
    name = "my-vpc"
}

resource "google_compute_subnetwork" "public_subnet" {
    name          = "public-subnet"
    ip_cidr_range = "10.0.0.0/24"
    region        = "us-central1"
    network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "private_subnet" {
    name          = "private-subnet"
    ip_cidr_range = "10.0.1.0/24"
    region        = "us-central1"
    network       = google_compute_network.vpc_network.id
}

resource "google_compute_instance" "web_instance" {
    name         = "web-instance"
    machine_type = "e2-medium"
    zone         = "us-central1-a"
    tags         = ["http-server"]

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.public_subnet.name
        access_config {}
    }

    metadata_startup_script = <<-EOT
        #!/bin/bash
        sudo apt-get update
        sudo apt-get install -y nginx
    EOT
}

resource "google_compute_firewall" "default-allow-http" {
    name    = "allow-http"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "tcp"
        ports    = ["80", "443"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["http-server"]
}
