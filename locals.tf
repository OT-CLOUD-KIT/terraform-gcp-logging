locals {
  bucket_names = {
    for key, bucket in var.log_buckets :
    key => "projects/${var.project_id}/locations/${bucket.location}/buckets/${key}"
  }

  bucket_destinations = {
    for key, name in local.bucket_names :
    key => "logging.googleapis.com/${name}"
  }

  notification_channel_ids = {
    for key, channel in google_monitoring_notification_channel.channel :
    key => channel.id
  }
}
