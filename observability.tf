resource "google_monitoring_notification_channel" "channel" {
  for_each = var.notification_channels

  depends_on = [terraform_data.dependency_getter]

  project      = var.project_id
  display_name = each.value.display_name
  type         = each.value.type
  description  = each.value.description
  enabled      = each.value.enabled
  labels       = each.value.labels
  user_labels  = each.value.user_labels
}

resource "google_monitoring_alert_policy" "policy" {
  for_each = var.alert_policies

  depends_on = [
    terraform_data.dependency_getter,
    google_monitoring_notification_channel.channel,
  ]

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = each.value.combiner
  enabled      = each.value.enabled
  severity     = each.value.severity
  user_labels  = each.value.user_labels
  notification_channels = distinct(concat(
    tolist(each.value.notification_channel_ids),
    [for key in each.value.notification_channel_keys : local.notification_channel_ids[key]],
  ))

  dynamic "documentation" {
    for_each = each.value.documentation == null ? [] : [each.value.documentation]
    content {
      content   = documentation.value.content
      mime_type = documentation.value.mime_type
      subject   = documentation.value.subject
    }
  }

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      condition_threshold {
        filter          = conditions.value.filter
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value
        duration        = conditions.value.duration

        aggregations {
          alignment_period     = conditions.value.alignment_period
          per_series_aligner   = conditions.value.per_series_aligner
          cross_series_reducer = conditions.value.cross_series_reducer
          group_by_fields      = conditions.value.group_by_fields
        }

        trigger {
          count = conditions.value.trigger_count
        }
      }
    }
  }
}

resource "google_monitoring_dashboard" "dashboard" {
  for_each = var.monitoring_dashboards

  depends_on = [terraform_data.dependency_getter]

  project        = var.project_id
  dashboard_json = each.value
}

resource "google_billing_budget" "budget" {
  for_each = var.billing_budgets

  depends_on = [
    terraform_data.dependency_getter,
    google_monitoring_notification_channel.channel,
  ]

  billing_account = each.value.billing_account
  display_name    = each.value.display_name
  ownership_scope = each.value.ownership_scope
  deletion_policy = each.value.deletion_policy

  budget_filter {
    projects               = each.value.projects
    resource_ancestors     = each.value.resource_ancestors
    services               = each.value.services
    credit_types_treatment = each.value.credit_types_treatment
    credit_types           = each.value.credit_types
    subaccounts            = each.value.subaccounts
    labels                 = each.value.labels
    calendar_period        = each.value.calendar_period
  }

  amount {
    specified_amount {
      currency_code = each.value.currency_code
      units         = each.value.amount_units
      nanos         = each.value.amount_nanos
    }
  }

  dynamic "threshold_rules" {
    for_each = each.value.threshold_rules
    content {
      threshold_percent = threshold_rules.value.threshold_percent
      spend_basis       = threshold_rules.value.spend_basis
    }
  }

  all_updates_rule {
    pubsub_topic   = each.value.pubsub_topic
    schema_version = each.value.pubsub_topic == null ? null : "1.0"
    monitoring_notification_channels = distinct(concat(
      tolist(each.value.notification_channel_ids),
      [for key in each.value.notification_channel_keys : local.notification_channel_ids[key]],
    ))
    disable_default_iam_recipients  = each.value.disable_default_iam_recipients
    enable_project_level_recipients = each.value.enable_project_level_recipients
  }
}

resource "google_scc_v2_organization_notification_config" "notification" {
  for_each = var.scc_notification_configs

  depends_on = [terraform_data.dependency_getter]

  organization    = each.value.organization_id
  location        = each.value.location
  config_id       = each.key
  description     = each.value.description
  pubsub_topic    = each.value.pubsub_topic
  deletion_policy = each.value.deletion_policy

  streaming_config {
    filter = each.value.filter
  }
}
