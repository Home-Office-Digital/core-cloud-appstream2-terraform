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
    fleet_name      = string
    image_arn       = string
    min_capacity    = number
    max_capacity    = number
    scale_up_cron   = string
    scale_down_cron = string
    min_wh_capacity = number
    max_wh_capacity = number
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

variable "attach_vpc_to_r53_profile" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type    = string
  default = ""
}