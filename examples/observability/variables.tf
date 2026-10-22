variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "organization_id" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "notification_email" {
  type = string
}

variable "monthly_budget_units" {
  type    = string
  default = "300"
}

variable "scc_pubsub_topic" {
  type = string
}
