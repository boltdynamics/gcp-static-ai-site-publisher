terraform {
  required_providers {
    google = {
      version = ">= 5.40.0"
    }
    googlesiteverification = {
      source  = "hectorj/googlesiteverification"
      version = ">= 0.4.5"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.39.0"
    }
  }
}

provider "google" {
  impersonate_service_account = "terraform-cloudbuild-sa@pras-sandbox-405410.iam.gserviceaccount.com"
  project = var.project_id
  region  = var.region
  zone    = var.zone
  # scopes  = ["https://www.googleapis.com/auth/siteverification"]
}
