
terraform {
  required_version = ">= 0.14"

  required_providers {
    google = ">= 3.3"
  }
}
provider "google" {
  project = "ledn-test"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
}

resource "google_cloud_run_service" "run_service" {
  name = "nginx"
  location = "us-west2"

  template {
    spec {
      containers {
        image = "us-west2-docker.pkg.dev/ledn-test/ledn-repo/ledn-nginx:1.0"
        ports {
          container_port = 80
      }
    }
  }
}

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run_api]
}

resource "google_cloud_run_service_iam_member" "allow_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_service.run_service.status[0].url
}