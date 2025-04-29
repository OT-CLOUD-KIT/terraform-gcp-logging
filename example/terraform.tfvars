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
