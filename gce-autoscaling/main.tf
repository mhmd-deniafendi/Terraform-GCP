provider "google" {
    project = "storied-courier-350802"
    region  = "asia-southeast2"
}

resource "google_compute_address" "static" {
    name    = "ipv4-address" 
}

resource "google_compute_instance_template" "default" {
    name        = "app-server-template"
    description = "This image template for manage nodegroup app server"

    tags = [ "dkatalis" ]

    labels = {
        environment = "dev"
    }

    instance_description = "Assigned to instance"
    machine_type = "e2-micro"
    region = "asia-southeast2"

    scheduling {
      automatic_restart = true
    }

    disk {
      source_image  = "debian-cloud/debian-10"
      auto_delete   = true
      boot          = true
    }

    network_interface {
      network       = "default"
      access_config {
        nat_ip      = google_compute_address.static.address
      }
    }

    service_account {
      scopes        = [ "cloud-platform" ]
    }
}   

resource "google_compute_instance_group_manager" "default"{
    name    = "appserver-dev"

    base_instance_name = "app-o1"
    zone               = "asia-southeast2-a"
    description        = "Compute Engine from Instance Group"

    version {
        instance_template  = google_compute_instance_template.default.id
    }
}

resource "google_compute_http_health_check" "default" {
    name               = "atuhentication-health-check"
    request_path       =  "/health-check"  
}

data "google_compute_image" "debian_10" {
    family          = "debian-10"
    project         = "debian-cloud"
}

resource "google_compute_autoscaler" "default" {
    name            = "autoscaler-dev"
    zone            = "asia-southeast2-a"
    target          = google_compute_instance_group_manager.default.id

    autoscaling_policy {
      max_replicas      = 2
      min_replicas      = 1
      cooldown_period   = 600
      cpu_utilization {
        target = 0.8
      }
    }
}

resource "google_compute_firewall" "default" {
    name    = "custom-ingress"
    network = "default"
    
    allow {
      protocol = "tcp"
      ports    = ["5000", "80", "443", "8080"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["dkatalis"]
}
