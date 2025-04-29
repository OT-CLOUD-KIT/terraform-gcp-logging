resource "google_logging_project_bucket_config" "log_bucket" {
for_each = var.create_bucket == true ? toset(var.bucket_ids) : toset([])

  project        = var.project_id
  location       = var.location
  retention_days = var.retention_days != null ? var.retention_days : 30 # Default to 30 days if null
  bucket_id      = each.key
  description    = var.description != "" ? var.description : "Default bucket description" # Default description if empty

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_logging_project_sink" "log_sink" {
  for_each         = toset(var.sink_names) # Loop through multiple sink names
  name             = each.key
  project          = var.project_id
  destination      = "logging.googleapis.com/projects/${var.project_id}/locations/${var.location}/buckets/${var.bucket_ids[0]}" # You can modify this for different buckets per sink
  filter           = var.filter
}
