# Terraform GCP Logging

Reusable Terraform module for centralized logging, monitoring, Security Command Center notifications, dashboards, alerting, and billing budgets on Google Cloud.

The module supports independent configuration for every bucket and sink. A sink can write to a bucket managed by this module or to an external Cloud Logging, Cloud Storage, BigQuery, Pub/Sub, or project destination.

## Features

- Multiple logging buckets with individual locations and retention periods
- Optional CMEK encryption for logging buckets
- Optional bucket locking and Log Analytics
- Multiple sinks with independent filters and destinations
- Managed-bucket destinations without hard-coded list indexes
- External Cloud Logging, Cloud Storage, BigQuery, Pub/Sub, and project destinations
- Unique or custom sink writer identities
- Sink exclusions, disable controls, and BigQuery partitioning
- Counter-based log metrics
- Cloud Monitoring notification channels and metric-threshold alert policies
- Cloud Monitoring dashboards supplied as validated JSON
- SCC v2 organization finding notifications to Pub/Sub
- Billing budgets with current or forecast spend thresholds
- Input validation for bucket references and sink configuration

## Upgrade from the previous module

| Area | Previous module | Enhanced module |
| --- | --- | --- |
| Bucket input | One common configuration with `bucket_ids` | `log_buckets` map with independent settings |
| Sink routing | Every sink used `bucket_ids[0]` | Each sink selects `bucket_key` or an external `destination` |
| Retention | One shared value | Per-bucket retention |
| Encryption | Google-managed encryption only | Optional CMEK |
| Bucket controls | Basic bucket creation | Locking and Log Analytics options |
| Sink controls | Name and common filter | Per-sink filter, description, disabled state, deletion policy, and exclusions |
| External export | Not supported by the interface | Cloud Storage, BigQuery, Pub/Sub, Logging bucket, or project destinations |
| Writer identity | Not exposed | Exposed for destination IAM grants |
| Log metrics | Not available | Counter-based metrics with optional bucket scope |
| SCC | Not available | SCC v2 finding notifications to Pub/Sub |
| Alerting | Not available | Reusable Monitoring notification channels and threshold policies |
| Dashboards | Not available | Cloud Monitoring dashboard management |
| Cost controls | Not available | Billing budgets, thresholds, and notification routing |
| Validation | No cross-input validation | Invalid or unknown bucket references fail before apply |

## Usage

```hcl
module "logging" {
  source = "git::https://github.com/OT-CLOUD-KIT/terraform-gcp-logging.git?ref=v0.1.0"

  project_id = "example-project"

  log_buckets = {
    application = {
      location         = "global"
      retention_days   = 30
      description      = "Application logs"
      enable_analytics = true
    }

    security = {
      location       = "global"
      retention_days = 365
      description    = "Security and audit logs"
      kms_key_name   = "projects/example-project/locations/global/keyRings/logging/cryptoKeys/log-bucket"
    }
  }

  log_sinks = {
    application-errors = {
      bucket_key  = "application"
      description = "Route application errors to the application bucket"
      filter      = "resource.type=\"k8s_container\" AND severity>=ERROR"

      exclusions = {
        health-checks = {
          filter      = "httpRequest.requestUrl:\"/health\""
          description = "Exclude routine health checks"
        }
      }
    }

    audit-archive = {
      destination = "storage.googleapis.com/example-audit-archive"
      filter      = "log_id(\"cloudaudit.googleapis.com/activity\")"
    }
  }

  log_metrics = {
    application-errors = {
      description = "Number of application error entries"
      filter      = "resource.type=\"k8s_container\" AND severity>=ERROR"
      bucket_key  = "application"
    }
  }

  notification_channels = {
    platform-email = {
      display_name = "Platform team email"
      type         = "email"
      labels = {
        email_address = "platform@example.com"
      }
    }
  }

  alert_policies = {
    gke-error-rate = {
      display_name              = "GKE error log count"
      notification_channel_keys = ["platform-email"]
      severity                  = "ERROR"

      conditions = {
        errors = {
          display_name    = "Error count is high"
          filter          = "metric.type=\"logging.googleapis.com/user/application-errors\" AND resource.type=\"k8s_container\""
          comparison      = "COMPARISON_GT"
          threshold_value = 10
          duration        = "60s"
        }
      }
    }
  }

  monitoring_dashboards = {
    logging-overview = jsonencode({
      displayName = "Logging Overview"
      mosaicLayout = {
        columns = 12
        tiles   = []
      }
    })
  }

  billing_budgets = {
    monthly-platform = {
      billing_account          = "billingAccounts/000000-000000-000000"
      display_name             = "Monthly platform budget"
      amount_units             = "300"
      projects                 = ["projects/123456789012"]
      notification_channel_keys = ["platform-email"]
    }
  }

  scc_notification_configs = {
    active-high-severity = {
      organization_id = "123456789012"
      pubsub_topic    = "projects/example-project/topics/scc-findings"
      filter          = "state = \"ACTIVE\" AND severity = \"HIGH\""
      description     = "Active high-severity SCC findings"
    }
  }
}
```

For an external destination, grant the required destination role to the identity returned in `sink_writer_identities`. The destination resource and its IAM policy remain outside this module so ownership stays explicit.

## Inputs

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| `project_id` | GCP project in which resources are managed | `string` | n/a | yes |
| `log_buckets` | Logging buckets keyed by bucket ID | `map(object)` | `{}` | no |
| `log_sinks` | Project sinks keyed by sink name | `map(object)` | `{}` | no |
| `log_metrics` | Counter-based log metrics keyed by metric name | `map(object)` | `{}` | no |
| `notification_channels` | Cloud Monitoring notification channels | `map(object)` | `{}` | no |
| `alert_policies` | Metric-threshold alert policies | `map(object)` | `{}` | no |
| `monitoring_dashboards` | Dashboard JSON documents | `map(string)` | `{}` | no |
| `billing_budgets` | Billing budgets and threshold notifications | `map(object)` | `{}` | no |
| `scc_notification_configs` | SCC v2 organization finding notifications | `map(object)` | `{}` | no |
| `dependencies` | Values used for explicit external dependencies | `list(string)` | `[]` | no |

### `log_buckets` object

| Attribute | Type | Default | Description |
| --- | --- | --- | --- |
| `location` | `string` | `global` | Bucket location |
| `retention_days` | `number` | `30` | Log retention period |
| `description` | `string` | `null` | Bucket description |
| `locked` | `bool` | `false` | Irreversibly lock the retention policy |
| `enable_analytics` | `bool` | `false` | Enable Log Analytics |
| `kms_key_name` | `string` | `null` | CMEK CryptoKey resource name |

### `log_sinks` object

Each sink must set exactly one of `bucket_key` or `destination`.

| Attribute | Type | Default | Description |
| --- | --- | --- | --- |
| `bucket_key` | `string` | `null` | Key of a bucket in `log_buckets` |
| `destination` | `string` | `null` | Full external sink destination |
| `filter` | `string` | `""` | Logging advanced filter |
| `description` | `string` | `null` | Sink description |
| `disabled` | `bool` | `false` | Disable routing without deleting the sink |
| `unique_writer_identity` | `bool` | `true` | Create a unique service account for the sink |
| `custom_writer_identity` | `string` | `null` | Custom sink writer identity |
| `deletion_policy` | `string` | `DELETE` | `DELETE`, `ABANDON`, or `PREVENT` |
| `use_partitioned_tables` | `bool` | `null` | BigQuery partitioned table option |
| `exclusions` | `map(object)` | `{}` | Per-sink exclusion filters |

## Outputs

| Name | Description |
| --- | --- |
| `log_buckets` | Bucket IDs, names, locations, settings, and sink destinations |
| `log_sinks` | Sink IDs, destinations, status, and writer identities |
| `sink_writer_identities` | Writer identity keyed by sink name |
| `log_metrics` | Log-based metric IDs and names |
| `notification_channels` | Monitoring notification channel IDs |
| `alert_policies` | Monitoring alert policy IDs |
| `monitoring_dashboards` | Monitoring dashboard IDs |
| `billing_budgets` | Billing budget resource names |
| `scc_notification_configs` | SCC config names and publisher service accounts |

## Requirements

| Name | Version |
| --- | --- |
| Terraform | `>= 1.6.0` |
| Google provider | `~> 7.0` |

## Important considerations

- Locking a logging bucket is irreversible. Review retention requirements before setting `locked = true`.
- A CMEK key must be in a location compatible with the logging bucket, and the Cloud Logging service agent needs permission to use it.
- Creating an external sink does not automatically grant its writer identity access to the external destination.
- SCC must already be enrolled for the organization. Grant the returned SCC service account `roles/pubsub.publisher` on its target topic.
- Budget project filters require project numbers in `projects/PROJECT_NUMBER` format, not project IDs.
- Billing-budget creation requires billing-account permissions and the Cloud Billing Budget API.
- Alert policies and dashboards require the Cloud Monitoring API. Their filters must reference valid resource and metric types.
