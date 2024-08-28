locals {
  files = {
    "index.html" = {
      source       = local_file.rendered_index_html.filename
      content_type = "text/html"
    }
    "404.html" = {
      source       = local_file.rendered_html_404.filename
      content_type = "text/html"
    }
    "error.png" = {
      source       = "../error.png"
      content_type = "image/png"
    }
  }
}

resource "google_project_service" "siteverification" {
  service = "siteverification.googleapis.com"
}

data "googlesiteverification_dns_token" "domain" {
  domain     = var.domain_name
  depends_on = [google_project_service.siteverification]
}

data "google_secret_manager_secret_version" "cloudflare-api-key" {
  project  = var.project_id
  provider = google-beta
  secret   = "cloudflare-api-key"
}

provider "cloudflare" {
  api_token = data.google_secret_manager_secret_version.cloudflare-api-key.secret_data
}

data "cloudflare_zones" "zones" {
  filter {
    name = var.domain_name
  }
}

resource "cloudflare_record" "siteverification" {
  zone_id = data.cloudflare_zones.zones.zones.0.id
  name    = var.domain_name
  type    = "TXT"
  content = data.googlesiteverification_dns_token.domain.record_value
  ttl     = 60
  proxied = false
  comment = "Google Domain verification record"
  tags    = []
}

resource "cloudflare_record" "cname_test_learnwithpras" {
  zone_id = data.cloudflare_zones.zones.zones.0.id
  name    = var.static_ai_website_bucket_name
  type    = "CNAME"
  content = "c.storage.googleapis.com"
  proxied = true
  comment = "CNAME record pointing to Google Cloud Storage"
}

resource "google_storage_bucket" "website_bucket" {
  name          = var.static_ai_website_bucket_name
  location      = var.region
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_iam_binding" "public_access" {
  bucket = google_storage_bucket.website_bucket.name

  role = "roles/storage.objectViewer"

  members = [
    "allUsers"
  ]
}

data "template_file" "index_html" {
  template = file("../${path.module}/index.html.tpl")

  vars = {
    cloud_function_url = google_cloudfunctions2_function.ask-ai-function.url
  }
}

resource "local_file" "rendered_index_html" {
  content  = data.template_file.index_html.rendered
  filename = "${path.module}/rendered_index.html"
}

data "template_file" "html_404" {
  template = file("../${path.module}/404.html.tpl")

  vars = {
    website_domain = var.static_ai_website_bucket_name
  }
}

resource "local_file" "rendered_html_404" {
  content  = data.template_file.html_404.rendered
  filename = "${path.module}/rendered_404.html"
}

resource "google_storage_bucket_object" "website_files" {
  for_each     = local.files
  name         = each.key
  bucket       = google_storage_bucket.website_bucket.name
  source       = each.value.source
  content_type = each.value.content_type
}

data "google_iam_policy" "p4sa-secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  secret_id   = "projects/${var.project_number}/secrets/${var.github_secret_name}"
  policy_data = data.google_iam_policy.p4sa-secretAccessor.policy_data
}

resource "google_cloudbuildv2_connection" "github-connection" {
  location = var.region
  name     = "github-connection"

  github_config {
    app_installation_id = 53173798
    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_number}/secrets/${var.github_secret_name}/versions/latest"
    }
  }
}

resource "google_cloudbuildv2_repository" "static-ai-repository" {
  location          = var.region
  parent_connection = google_cloudbuildv2_connection.github-connection.name
  name              = "gcp-static-ai-site-publisher"
  remote_uri        = "https://github.com/boltdynamics/gcp-static-ai-site-publisher.git"
}

resource "google_cloudbuild_trigger" "build-static-ai-website" {
  location    = var.region
  name        = "build-static-ai-website"
  description = "Build the static ai website when there are changes to the repository"
  service_account = "terraform-cloudbuild-sa@pras-sandbox-405410.iam.gserviceaccount.com"
  repository_event_config {
    repository = google_cloudbuildv2_repository.static-ai-repository.id
    push {
      branch = "test-trigger"
    }
  }
  filename = "cloudbuild.yaml"
  substitutions = {
    _BUCKET_NAME = var.static_ai_website_bucket_name
  }
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

data "archive_file" "ask_ai_function_archive" {
  type        = "zip"
  source_dir  = "../dist"
  output_path = "ask-ai-function-bundle.zip"
}

resource "google_storage_bucket_object" "ask_ai_function_artifact" {
  source       = data.archive_file.ask_ai_function_archive.output_path
  content_type = "application/zip"
  name         = "src-${data.archive_file.ask_ai_function_archive.output_md5}.zip"
  bucket       = var.backend_bucket_name
}

resource "google_cloudfunctions2_function" "ask-ai-function" {
  name        = "ask-ai-function"
  description = "This function handles user queries from the static website and forwards them to the Gemini AI system. It then returns the response to the user."
  location    = var.region

  build_config {
    runtime     = "nodejs22"
    entry_point = "askGemini"

    source {
      storage_source {
        bucket = var.backend_bucket_name
        object = google_storage_bucket_object.ask_ai_function_artifact.name
      }
    }

    environment_variables = {
      PROJECT_ID = var.project_id
      REGION     = var.region
    }
  }

  service_config {
    available_memory               = "128Mi"
    available_cpu                  = 1
    timeout_seconds                = 30
    max_instance_count             = 1
    ingress_settings               = "ALLOW_ALL"
    all_traffic_on_latest_revision = true

    secret_environment_variables {
      project_id = var.project_id
      version    = "latest"
      key        = "GEMINI_AI_API_KEY"
      secret     = "xplorers-gemini-ai-api-key"
    }

    environment_variables = {
      PROJECT_ID = var.project_id
      REGION     = var.region
    }
  }


  labels = {
    env = "production"
  }
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.ask-ai-function.project
  location = google_cloudfunctions2_function.ask-ai-function.location
  service  = google_cloudfunctions2_function.ask-ai-function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_binding" "secret_manager_accessor_binding" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  ]
}
