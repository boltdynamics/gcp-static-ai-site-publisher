variable "domain_name" {
  description = "The domain name used for the website"
  type        = string
  default     = "learnwithpras.xyz"
}

variable "static_ai_website_bucket_name" {
  description = "The domain name to verify ownership of"
  type        = string
}

variable "project_id" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "region" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "zone" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "backend_bucket_name" {
  type     = string
  nullable = false
}

variable "project_number" {
  type     = string
  nullable = false
}

variable "github_secret_name" {
  type    = string
  default = "connect-github-github-oauthtoken-b6739d"
}
