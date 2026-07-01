# Appstream Fleet
variable "desired_instances" {
  description = "(Optional) Desired number of streaming instances"
  type        = number
}

variable "description" {
  description = "(Optional) Description to display for the AppStream fleet"
  type        = string
}

variable "idle_disconnect_timeout_in_seconds" {
  description = "(Optional) Amount of time that users can be idle (inactive) before they are disconnected from their streaming session and the disconnect_timeout_in_seconds time interval begins. Defaults to 0. Valid value is between 60 and 3600seconds."
  type        = number
}

variable "disconnect_timeout_in_seconds" {
  description = "(Optional) Amount of time that a streaming session remains active after users disconnect."
  type        = number
}

variable "display_name" {
  description = "(Optional) Human-readable friendly name for the AppStream fleet"
  type        = string
}

variable "enable_default_internet_access" {
  description = "(Optional) Enables or disables default internet access for the fleet."
  type        = bool
}

variable "fleet_type" {
  description = "(Optional) Fleet type. Valid values are: (e.g. \"ALWAYS_ON\" or \"ON_DEMAND\")"
  type        = string
}

variable "stream_view" {
  description = "(Optional) AppStream 2.0 view that is displayed to your users when they stream from the fleet."
  type        = string
  # default = "APP"
}

# Multi-fleet autoscaling configs
variable "fleet_configs" {
  description = "List of fleet-specific autoscaling configs"
  type = list(object({
    fleet_name                  = string
    image_arn                   = string
    min_capacity                = number
    max_capacity                = number
    scale_up_cron               = optional(string)
    scale_down_cron             = optional(string)
    min_wh_capacity             = optional(number)
    max_wh_capacity             = optional(number)
    desired_instances           = optional(number)
    scale_in_adjustment         = optional(number)
    scale_out_adjustment        = optional(number)
    scale_in_cooldown           = optional(number)
    scale_out_cooldown          = optional(number)
    metric_aggregation_type     = optional(string)
    scale_in_evaluation_periods = optional(number)
    scale_in_alarm_period       = optional(number)
    scale_in_alarm_threshold    = optional(number)
    scale_in_alarm_statistic       = optional(string)
    scale_out_alarm_statistic      = optional(string)
    scale_in_step_use_upper_bound  = optional(bool)
    scale_in_metric_interval_upper_bound = optional(number)
    scale_in_alarm_description     = optional(string)
    scale_out_alarm_description    = optional(string)
    scheduled_actions = optional(list(object({
      name         = string
      schedule     = string
      min_capacity = number
      max_capacity = number
    })))
    extra_scale_out_policies = optional(list(object({
      name_suffix         = string
      metric_name         = string
      comparison_operator = string
      threshold           = number
      scaling_adjustment  = number
      statistic           = optional(string)
      period              = optional(number)
      evaluation_periods  = optional(number)
      cooldown            = optional(number)
      metric_aggregation_type = optional(string)
    })))
    # Set false when extended autoscaling was created manually in AWS and cannot be imported
    # (scheduled actions do not support terraform import).
    manage_extended_autoscaling = optional(bool)
  }))
}

variable "associated_fleet" {
  description = "The fleet_name from fleet_configs to associate with the Stack"
  type        = string
}

variable "instance_type" {
  description = "(Required) Instance type to use when launching fleet instances"
  type        = string
}
variable "max_user_duration_in_seconds" {
  description = "(Optional) Maximum amount of time that a streaming session can remain active, in seconds."
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs for the fleet’s VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the fleet"
  type        = list(string)
}

# Appstream Stack
variable "stack_name" {
  description = "(Required) Unique name for the AppStream stack."
  type        = string
}

variable "stack_description" {
  description = "(Optional) Description for the AppStream stack"
  type        = string
}

variable "stack_display_name" {
  description = "(Optional) Human-readable display name for the AppStream Stack"
  type        = string
}

variable "region" {
  description = "AWS region in which to deploy AppStream resources"
  type        = string
}

variable "enable_homefolder" {
  description = "Enable or disable the HOMEFOLDER storage connector on the Stack."
  type        = bool
  # default     = false  # Default to false to disable HOMEFOLDER
}

// Scalling Policy
variable "scale_out_metric_interval_upper_bound" {
  description = "Lower bound for triggering scale-out StepScaling policy (metric interval)"
  type        = number
}

variable "scale_out_adjustment" {
  description = "Percentage change in capacity for scale-out StepScaling policy"
  type        = number
}

variable "scale_in_metric_interval_upper_bound" {
  description = "Lower bound for triggering scale-in StepScaling policy (metric interval)"
  type        = number
}

variable "scale_in_adjustment" {
  description = "Percentage change in capacity for scale-in StepScaling policy"
  type        = number
}

variable "user_settings" {
  description = "List of user settings for the Stack (action + permission)"
  type = list(object({
    action     = string
    permission = string
  }))
  default = [
    { action = "AUTO_TIME_ZONE_REDIRECTION", permission = "DISABLED" },
    { action = "CLIPBOARD_COPY_FROM_LOCAL_DEVICE", permission = "DISABLED" },
    { action = "CLIPBOARD_COPY_TO_LOCAL_DEVICE", permission = "DISABLED" },
    { action = "DOMAIN_PASSWORD_SIGNIN", permission = "ENABLED" },
    { action = "DOMAIN_SMART_CARD_SIGNIN", permission = "DISABLED" },
    { action = "FILE_DOWNLOAD", permission = "DISABLED" },
    { action = "FILE_UPLOAD", permission = "DISABLED" },
    { action = "PRINTING_TO_LOCAL_DEVICE", permission = "DISABLED" },
  ]
}

variable "route53_profile_name" {
  description = "The Route 53 profile name with which to associate the VPC."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The VPC Id to associate with the Route 53 profile."
  type        = string
  default     = ""
}