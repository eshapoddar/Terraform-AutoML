variable "project_id" {
  type = string
  default = "mlops-test-394614"
}

variable "new_project_id" {
  type = string
  default = "mlops-table12"
}

variable "new_project_name" {
  type = string
  default = "table-model"
}

variable "billing_account" {
  type = string
  default = "015AE9-A26C8D-07AA0F"
  
}

variable "region" {
  type = string
  default ="us-central1"
}

variable "zone" {
  type = string
  default ="us-central1-c"
}

variable "service_account_id" {
  type = string
  default ="automl-vision-sa-m3"
}

variable "service_account_display_name" {
  type = string
  default ="AutoML Vision Service Account"
}

variable "bucket_name" {
  type = string
  default ="model3table"
}

variable "bucket_location" {
  type = string
  default ="US-CENTRAL1"
}

