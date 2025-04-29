# Terraform GCP Cloud Logging

[![Opstree Solutions][opstree_avatar]][opstree_homepage]<br/>[Opstree Solutions][opstree_homepage] 

  [opstree_homepage]: https://opstree.github.io/
  [opstree_avatar]: https://img.cloudposse.com/150x150/https://github.com/opstree.png

This Terraform module creates multiple Cloud Logging Buckets and Log Sinks in a GCP project.
It dynamically creates buckets based on the bucket_ids list and assigns retention policies and descriptions.
Log sinks are created for each name in sink_names, with logs directed to a specified logging bucket.
Defaults like retention and description are handled if not explicitly provided, and bucket destruction is allowed.

## Architecture

<img width="800" length="800" alt="Terraform" src="https://github.com/user-attachments/assets/64793e81-1c43-4bbc-a2a5-4fbfa2b3af03">

## Providers

| Name                                              | Version  |
|---------------------------------------------------|----------|
| <a name="provider_gcp"></a> [gcp](#provider\_gcp) | 5.0.0   |

## Usage

```hcl
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

# Variable values

# Example to create multiple buckets and sinks
region = "us-central1"

project_id = "nw-opstree-dev-landing-zone"

location         = "global"
retention_days   = 30
bucket_ids       = ["log-bucket-3", "log-bucket-4"]
description      = "Bucket for storing logs."
sink_names       = ["sink-1", "sink-2"]
filter          = "logName=\"projects/[nw-opstree-dev-landing-zone]/logs/cloudaudit.googleapis.com%2Factivity\""
create_bucket    = true

```

## Inputs

| Name | Description | Type | Default | Required | 
|------|-------------|:----:|---------|:--------:|
|**project_id**| The ID of the project | string | { } | yes| 
|**region**| Region where resource will be created. | string | "us-central1" | yes | 
|**location**| Location for the logging bucket | string | global | yes| 
|**retention_days**| Retention days for logs (used if creating bucket) | number | null | yes |
|**bucket_ids**| List of IDs for the buckets to create or use | list(string) | [ ] | yes| 
|**description**| Description for the bucket | string | " " | yes | 
|**sink_names**| List of names for the log sinks to create | list(string) | [ ] | yes| 
|**filter**| Log filter for the sink | string | " " | yes |  
|**create_bucket**| Whether to create a new bucket or use existing | bool | true | yes |  


## Output
| Name | Description |
|------|-------------|
|**log_bucket_ids**| IDs of the created or referenced log buckets | 
|**log_sink_names**| Names of the created log sinks | 
