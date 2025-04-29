module "cloud_logging" {
  source = "./module"

  project_id       = var.project_id
  location         = var.location
  retention_days   = var.retention_days
  bucket_ids       = var.bucket_ids
  description      = var.description
  sink_names       = var.sink_names
  filter           = var.filter
  create_bucket    = var.create_bucket
}
