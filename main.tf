resource "terraform_data" "dependency_getter" {
  input = var.dependencies
}

resource "google_logging_project_bucket_config" "bucket" {
  for_each = var.log_buckets

  depends_on = [terraform_data.dependency_getter]

  project          = var.project_id
  location         = each.value.location
  bucket_id        = each.key
  retention_days   = each.value.retention_days
  description      = each.value.description
  locked           = each.value.locked
  enable_analytics = each.value.enable_analytics

  dynamic "cmek_settings" {
    for_each = each.value.kms_key_name == null ? [] : [each.value.kms_key_name]
    content {
      kms_key_name = cmek_settings.value
    }
  }
}

resource "google_logging_project_sink" "sink" {
  for_each = var.log_sinks

  depends_on = [
    terraform_data.dependency_getter,
    google_logging_project_bucket_config.bucket,
  ]

  project                = var.project_id
  name                   = each.key
  destination            = each.value.bucket_key == null ? each.value.destination : local.bucket_destinations[each.value.bucket_key]
  filter                 = each.value.filter
  description            = each.value.description
  disabled               = each.value.disabled
  unique_writer_identity = each.value.unique_writer_identity
  custom_writer_identity = each.value.custom_writer_identity
  deletion_policy        = each.value.deletion_policy

  dynamic "bigquery_options" {
    for_each = each.value.use_partitioned_tables == null ? [] : [each.value.use_partitioned_tables]
    content {
      use_partitioned_tables = bigquery_options.value
    }
  }

  dynamic "exclusions" {
    for_each = each.value.exclusions
    content {
      name        = exclusions.key
      description = exclusions.value.description
      filter      = exclusions.value.filter
      disabled    = exclusions.value.disabled
    }
  }
}

resource "google_logging_metric" "metric" {
  for_each = var.log_metrics

  depends_on = [
    terraform_data.dependency_getter,
    google_logging_project_bucket_config.bucket,
  ]

  project     = var.project_id
  name        = each.key
  description = each.value.description
  filter      = each.value.filter
  disabled    = each.value.disabled
  bucket_name = each.value.bucket_key == null ? null : local.bucket_names[each.value.bucket_key]
}
