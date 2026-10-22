module "observability" {
  source = "../.."

  project_id = var.project_id

  notification_channels = {
    platform-email = {
      display_name = "Platform team email"
      type         = "email"
      labels = {
        email_address = var.notification_email
      }
    }
  }

  alert_policies = {
    high-cpu = {
      display_name              = "High VM CPU utilization"
      notification_channel_keys = ["platform-email"]
      severity                  = "WARNING"

      conditions = {
        cpu = {
          display_name    = "CPU above 80 percent"
          filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
          threshold_value = 0.8
          duration        = "300s"
        }
      }
    }
  }

  monitoring_dashboards = {
    platform-overview = jsonencode({
      displayName = "Platform Overview"
      mosaicLayout = {
        columns = 12
        tiles   = []
      }
    })
  }

  billing_budgets = {
    monthly = {
      billing_account           = var.billing_account
      display_name              = "Monthly project budget"
      amount_units              = var.monthly_budget_units
      projects                  = ["projects/${var.project_number}"]
      notification_channel_keys = ["platform-email"]
    }
  }

  scc_notification_configs = {
    active-high-severity = {
      organization_id = var.organization_id
      pubsub_topic    = var.scc_pubsub_topic
      filter          = "state = \"ACTIVE\" AND severity = \"HIGH\""
      description     = "Active high-severity findings"
    }
  }
}
