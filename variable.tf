variable "project_id" {
  description = "The ID of the GCP project to create or use the logging bucket."
  type        = string
}

variable "location" {
  description = "Location for the logging bucket (e.g., global)."
  type        = string
  default     = "global"
}

variable "retention_days" {
  description = "Number of days to retain logs (used only if creating a bucket)."
  type        = number
  default     = null # Optional (can be set to null for no default)
}

variable "bucket_ids" {
  description = "A list of bucket IDs to create or use."
  type        = list(string)
}

variable "description" {
  description = "Description for the logging bucket."
  type        = string
  default     = "" # Optional (empty string is acceptable)
}

variable "sink_names" {
  description = "A list of sink names to create."
  type        = list(string)
}

variable "filter" {
  description = "Optional filter for log entries."
  type        = string
  default     = ""
}

variable "create_bucket" {
  description = "Set true to create a new logging bucket, false to use existing buckets."
  type        = bool
  default     = true
}
