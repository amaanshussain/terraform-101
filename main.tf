terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("servicekey.json")

  project = "terraform-101-417408"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_artifact_registry_repository" "art_reg" {
  format        = "DOCKER"
  location      = "us-central1"
  repository_id = "my-repo"
}

resource "google_cloud_run_service" "app_service" {
  name     = "express-webapp"
  location = google_artifact_registry_repository.art_reg.location
  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/terraform-101-417408/my-repo/express-webapp:1.1"
        ports {
          container_port = 3000
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.app_service.location
  project  = "terraform-101-417408"
  service  = google_cloud_run_service.app_service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
