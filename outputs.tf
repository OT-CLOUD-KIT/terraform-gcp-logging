output "log_buckets" {
  description = "Managed logging buckets keyed by input key."
  value = {
    for key, bucket in google_logging_project_bucket_config.bucket : key => {
      id               = bucket.id
      name             = bucket.name
      bucket_id        = bucket.bucket_id
      location         = bucket.location
      retention_days   = bucket.retention_days
      locked           = bucket.locked
      enable_analytics = bucket.enable_analytics
      destination      = local.bucket_destinations[key]
    }
  }
}

output "log_sinks" {
  description = "Managed project sinks, including the identity that needs destination permissions."
  value = {
    for key, sink in google_logging_project_sink.sink : key => {
      id              = sink.id
      name            = sink.name
      destination     = sink.destination
      writer_identity = sink.writer_identity
      disabled        = sink.disabled
    }
  }
}

output "sink_writer_identities" {
  description = "Writer identities keyed by sink name for granting access on external destinations."
  value = {
    for key, sink in google_logging_project_sink.sink : key => sink.writer_identity
  }
}

output "log_metrics" {
  description = "Managed log-based metrics keyed by input key."
  value = {
    for key, metric in google_logging_metric.metric : key => {
      id   = metric.id
      name = metric.name
    }
  }
}

output "notification_channels" {
  description = "Cloud Monitoring notification channel IDs keyed by input key."
  value       = local.notification_channel_ids
}

output "alert_policies" {
  description = "Cloud Monitoring alert policy IDs keyed by input key."
  value       = { for key, policy in google_monitoring_alert_policy.policy : key => policy.id }
}

output "monitoring_dashboards" {
  description = "Cloud Monitoring dashboard IDs keyed by input key."
  value       = { for key, dashboard in google_monitoring_dashboard.dashboard : key => dashboard.id }
}

output "billing_budgets" {
  description = "Billing budget resource names keyed by input key."
  value       = { for key, budget in google_billing_budget.budget : key => budget.name }
}

output "scc_notification_configs" {
  description = "SCC notification configuration names and publisher service accounts."
  value = {
    for key, config in google_scc_v2_organization_notification_config.notification : key => {
      name            = config.name
      service_account = config.service_account
    }
  }
}
