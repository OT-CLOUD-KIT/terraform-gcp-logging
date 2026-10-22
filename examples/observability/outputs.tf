output "alert_policies" {
  value = module.observability.alert_policies
}

output "monitoring_dashboards" {
  value = module.observability.monitoring_dashboards
}

output "billing_budgets" {
  value = module.observability.billing_budgets
}

output "scc_notification_configs" {
  value = module.observability.scc_notification_configs
}
