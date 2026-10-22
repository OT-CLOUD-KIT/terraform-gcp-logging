variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "Logging bucket location."
  type        = string
  default     = "global"
}
