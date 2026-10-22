variable "project_id" {
  description = "GCP project ID in which logging resources are managed."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must not be empty."
  }
}

variable "log_buckets" {
  description = "Logging buckets keyed by bucket ID. Bucket locking is irreversible after it is enabled."
  type = map(object({
    location         = optional(string, "global")
    retention_days   = optional(number, 30)
    description      = optional(string)
    locked           = optional(bool, false)
    enable_analytics = optional(bool, false)
    kms_key_name     = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for bucket in values(var.log_buckets) : bucket.retention_days >= 1
    ])
    error_message = "Every logging bucket must use retention_days of at least 1."
  }

  validation {
    condition = alltrue([
      for bucket in values(var.log_buckets) : length(trimspace(bucket.location)) > 0
    ])
    error_message = "Every logging bucket must have a non-empty location."
  }
}

variable "log_sinks" {
  description = "Project log sinks keyed by sink name. Set exactly one of bucket_key or destination."
  type = map(object({
    bucket_key             = optional(string)
    destination            = optional(string)
    filter                 = optional(string, "")
    description            = optional(string)
    disabled               = optional(bool, false)
    unique_writer_identity = optional(bool, true)
    custom_writer_identity = optional(string)
    deletion_policy        = optional(string, "DELETE")
    use_partitioned_tables = optional(bool)
    exclusions = optional(map(object({
      filter      = string
      description = optional(string)
      disabled    = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for sink in values(var.log_sinks) : (sink.bucket_key != null) != (sink.destination != null)
    ])
    error_message = "Each log sink must set exactly one of bucket_key or destination."
  }

  validation {
    condition = alltrue([
      for sink in values(var.log_sinks) : sink.bucket_key == null ? true : contains(keys(var.log_buckets), sink.bucket_key)
    ])
    error_message = "Every sink bucket_key must reference a key in log_buckets."
  }

  validation {
    condition = alltrue([
      for sink in values(var.log_sinks) : contains(["DELETE", "ABANDON", "PREVENT"], sink.deletion_policy)
    ])
    error_message = "Sink deletion_policy must be DELETE, ABANDON, or PREVENT."
  }

  validation {
    condition = alltrue([
      for sink in values(var.log_sinks) : sink.custom_writer_identity == null || sink.unique_writer_identity
    ])
    error_message = "custom_writer_identity requires unique_writer_identity = true."
  }
}

variable "log_metrics" {
  description = "Counter-based log metrics keyed by metric name. An optional bucket_key scopes a metric to a managed log bucket."
  type = map(object({
    filter      = string
    description = optional(string)
    disabled    = optional(bool, false)
    bucket_key  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for metric in values(var.log_metrics) : metric.bucket_key == null ? true : contains(keys(var.log_buckets), metric.bucket_key)
    ])
    error_message = "Every metric bucket_key must reference a key in log_buckets."
  }

  validation {
    condition = alltrue([
      for metric in values(var.log_metrics) : length(trimspace(metric.filter)) > 0
    ])
    error_message = "Every log metric must have a non-empty filter."
  }
}

variable "dependencies" {
  description = "Optional values used to create an explicit dependency on resources outside this module."
  type        = list(string)
  default     = []
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channels keyed by a stable logical name."
  type = map(object({
    display_name = string
    type         = string
    description  = optional(string)
    enabled      = optional(bool, true)
    labels       = map(string)
    user_labels  = optional(map(string), {})
  }))
  default = {}
}

variable "alert_policies" {
  description = "Cloud Monitoring metric-threshold alert policies keyed by a stable logical name."
  type = map(object({
    display_name              = string
    combiner                  = optional(string, "OR")
    enabled                   = optional(bool, true)
    severity                  = optional(string)
    user_labels               = optional(map(string), {})
    notification_channel_keys = optional(set(string), [])
    notification_channel_ids  = optional(set(string), [])
    documentation = optional(object({
      content   = string
      mime_type = optional(string, "text/markdown")
      subject   = optional(string)
    }))
    conditions = map(object({
      display_name         = string
      filter               = string
      comparison           = optional(string, "COMPARISON_GT")
      threshold_value      = number
      duration             = optional(string, "60s")
      alignment_period     = optional(string, "60s")
      per_series_aligner   = optional(string, "ALIGN_MEAN")
      cross_series_reducer = optional(string, "REDUCE_NONE")
      group_by_fields      = optional(list(string), [])
      trigger_count        = optional(number, 1)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in values(var.alert_policies) : length(policy.conditions) > 0
    ])
    error_message = "Every alert policy must define at least one condition."
  }

  validation {
    condition = alltrue(flatten([
      for policy in values(var.alert_policies) : [
        for key in policy.notification_channel_keys : contains(keys(var.notification_channels), key)
      ]
    ]))
    error_message = "Every alert-policy notification_channel_key must reference notification_channels."
  }

  validation {
    condition = alltrue([
      for policy in values(var.alert_policies) : contains(["AND", "OR", "AND_WITH_MATCHING_RESOURCE"], policy.combiner)
    ])
    error_message = "Alert policy combiner must be AND, OR, or AND_WITH_MATCHING_RESOURCE."
  }
}

variable "monitoring_dashboards" {
  description = "Cloud Monitoring dashboard JSON documents keyed by a stable logical name. Use jsonencode to build each document."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for document in values(var.monitoring_dashboards) : can(jsondecode(document))])
    error_message = "Every monitoring dashboard value must be valid JSON."
  }
}

variable "billing_budgets" {
  description = "Billing budgets keyed by a stable logical name. Project filters must use projects/PROJECT_NUMBER."
  type = map(object({
    billing_account        = string
    display_name           = string
    currency_code          = optional(string, "USD")
    amount_units           = string
    amount_nanos           = optional(number, 0)
    projects               = optional(set(string), [])
    resource_ancestors     = optional(set(string), [])
    services               = optional(set(string), [])
    credit_types_treatment = optional(string, "INCLUDE_ALL_CREDITS")
    credit_types           = optional(set(string), [])
    subaccounts            = optional(set(string), [])
    labels                 = optional(map(string), {})
    calendar_period        = optional(string, "MONTH")
    threshold_rules = optional(list(object({
      threshold_percent = number
      spend_basis       = optional(string, "CURRENT_SPEND")
      })), [
      { threshold_percent = 0.5, spend_basis = "CURRENT_SPEND" },
      { threshold_percent = 0.9, spend_basis = "CURRENT_SPEND" },
      { threshold_percent = 1.0, spend_basis = "CURRENT_SPEND" },
    ])
    notification_channel_keys       = optional(set(string), [])
    notification_channel_ids        = optional(set(string), [])
    pubsub_topic                    = optional(string)
    disable_default_iam_recipients  = optional(bool, false)
    enable_project_level_recipients = optional(bool, false)
    ownership_scope                 = optional(string, "ALL_USERS")
    deletion_policy                 = optional(string, "DELETE")
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for budget in values(var.billing_budgets) : [
        for key in budget.notification_channel_keys : contains(keys(var.notification_channels), key)
      ]
    ]))
    error_message = "Every budget notification_channel_key must reference notification_channels."
  }

  validation {
    condition = alltrue(flatten([
      for budget in values(var.billing_budgets) : [
        for rule in budget.threshold_rules : rule.threshold_percent >= 0
      ]
    ]))
    error_message = "Budget threshold percentages must be greater than or equal to zero."
  }

  validation {
    condition = alltrue([
      for budget in values(var.billing_budgets) : can(tonumber(budget.amount_units)) && tonumber(budget.amount_units) > 0
    ])
    error_message = "Every billing budget amount_units value must be a positive whole-number string."
  }

  validation {
    condition = alltrue(flatten([
      for budget in values(var.billing_budgets) : [
        for rule in budget.threshold_rules : contains(["CURRENT_SPEND", "FORECASTED_SPEND"], rule.spend_basis)
      ]
    ]))
    error_message = "Budget spend_basis must be CURRENT_SPEND or FORECASTED_SPEND."
  }

  validation {
    condition = alltrue([
      for budget in values(var.billing_budgets) : contains(["DELETE", "ABANDON", "PREVENT"], budget.deletion_policy)
    ])
    error_message = "Budget deletion_policy must be DELETE, ABANDON, or PREVENT."
  }
}

variable "scc_notification_configs" {
  description = "SCC v2 organization notification configurations keyed by config ID. SCC must already be enrolled."
  type = map(object({
    organization_id = string
    location        = optional(string, "global")
    description     = optional(string)
    pubsub_topic    = string
    filter          = string
    deletion_policy = optional(string, "DELETE")
  }))
  default = {}

  validation {
    condition = alltrue([
      for config in values(var.scc_notification_configs) : length(trimspace(config.filter)) > 0
    ])
    error_message = "Every SCC notification configuration must have a non-empty filter."
  }

  validation {
    condition = alltrue([
      for config in values(var.scc_notification_configs) : contains(["DELETE", "ABANDON", "PREVENT"], config.deletion_policy)
    ])
    error_message = "SCC deletion_policy must be DELETE, ABANDON, or PREVENT."
  }
}
