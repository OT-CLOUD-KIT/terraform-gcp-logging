module "logging" {
  source = "../.."

  project_id = var.project_id

  log_buckets = {
    application = {
      location         = var.location
      retention_days   = 30
      description      = "Application logs"
      enable_analytics = true
    }
  }

  log_sinks = {
    application-errors = {
      bucket_key  = "application"
      description = "Route GKE application errors"
      filter      = "resource.type=\"k8s_container\" AND severity>=ERROR"

      exclusions = {
        health-checks = {
          filter = "httpRequest.requestUrl:\"/health\""
        }
      }
    }
  }

  log_metrics = {
    application-errors = {
      description = "Application error count"
      filter      = "resource.type=\"k8s_container\" AND severity>=ERROR"
      bucket_key  = "application"
    }
  }
}
