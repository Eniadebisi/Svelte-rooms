variable "project_name" {
  type = string
}

variable "notification_email" {
  type        = string
  description = "Email address for budget threshold alerts"
}

variable "budget_limit_amount" {
  type        = string
  default     = "15"
  description = "Monthly cost budget limit in USD"
}
