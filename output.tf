output "log_bucket_ids" {
  description = "IDs of the created or referenced log buckets."
  value       = [for bucket in google_logging_project_bucket_config.log_bucket : bucket.bucket_id]
}

output "log_sink_names" {
  description = "Names of the created log sinks."
  value       = [for sink in google_logging_project_sink.log_sink : sink.name]
}
