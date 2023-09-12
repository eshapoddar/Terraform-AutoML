terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.76.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

// Create a new GCP project
resource "google_project" "new_project" {
  project_id = var.new_project_id
  name       = var.new_project_name
  billing_account = var.billing_account
}

// Wait for a certain amount of time to allow billing to activate
resource "null_resource" "wait_for_billing" {
  depends_on = [google_project.new_project]

  provisioner "local-exec" {
    command = "sleep 120"  # Wait for 2 minutes
  }
}
# Enable required APIs
resource "google_project_service" "storage_json_api" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "storage-api.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "automl_api" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "automl.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "storage_api" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "storage.googleapis.com"
}

resource "google_project_service" "iam_api" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "iam.googleapis.com"
}

// Create a service account and grant AutoML Editor role in the new project
resource "google_service_account" "automl_vision_sa" {
  depends_on = [null_resource.wait_for_billing]
  project     = var.new_project_id
  account_id  = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_member" "automl_editor_role" {
  depends_on = [google_service_account.automl_vision_sa]
  project = var.new_project_id
  role    = "roles/automl.editor"
  member  = "serviceAccount:${google_service_account.automl_vision_sa.email}"
}

// Create a Cloud Storage bucket in the new project
resource "google_storage_bucket" "ml_bucket" {
  depends_on = [null_resource.wait_for_billing]
  project       = var.new_project_id
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = true
}

// Copy the sample csv into the bucket
resource "null_resource" "copy_csv" {
  depends_on = [google_storage_bucket.ml_bucket]
  provisioner "local-exec" {
    command = "gsutil -m cp -R gs://cloud-ml-tables-data/bank-marketing.csv gs://${var.bucket_name}/"
  }
}

# Enable the Vertex AI API
resource "google_project_service" "vertex_ai_api" {
  depends_on = [null_resource.wait_for_billing]
  project = var.new_project_id
  service = "aiplatform.googleapis.com"
}

# Wait for API service to be enabled before continuing
resource "null_resource" "wait_for_vertex_ai_api" {
  depends_on = [google_project_service.vertex_ai_api]

  provisioner "local-exec" {
    command = "sleep 120"
  }
}

// Create a dataset in Vertex AI
resource "google_vertex_ai_dataset" "text_dataset" {
  depends_on = [null_resource.wait_for_vertex_ai_api]
  display_name        = "tabular-dataset"
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
  region              = "us-central1"
  project = var.new_project_id
}
