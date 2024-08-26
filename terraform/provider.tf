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
  project = var.project_id
  region  = var.region
  zone    = var.zone
  scopes  = [
    "https://www.googleapis.com/auth/siteverification",
    "https://www.googleapis.com/auth/siteverification.verify_only",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/sqlservice.login",
    "openid"
  ]
}
