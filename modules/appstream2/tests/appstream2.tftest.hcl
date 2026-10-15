provider "aws" {
  alias  = "test"
  region = "eu-west-2"

  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

run "plan_single_fleet_stack" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    region                             = "eu-west-2"
    desired_instances                  = 1
    description                        = "Test fleet"
    idle_disconnect_timeout_in_seconds = 600
    disconnect_timeout_in_seconds      = 60
    display_name                       = "Test Fleet"
    enable_default_internet_access     = false
    fleet_type                         = "ON_DEMAND"
    stream_view                        = "APP"
    instance_type                      = "stream.standard.small"
    max_user_duration_in_seconds       = 3600

    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
    security_group_ids = ["sg-12345678"]

    stack_name         = "test-stack"
    stack_description  = "Test stack"
    stack_display_name = "Test Stack"
    enable_homefolder  = false

    associated_fleet = "fleet-a"
    fleet_configs = [
      {
        fleet_name      = "fleet-a"
        image_arn       = "arn:aws:appstream:eu-west-2:123456789012:image/test-image"
        min_capacity    = 1
        max_capacity    = 3
        scale_up_cron   = "cron(0 8 ? * MON-FRI *)"
        scale_down_cron = "cron(0 18 ? * MON-FRI *)"
        min_wh_capacity = 1
        max_wh_capacity = 2
      }
    ]

    scale_out_metric_interval_upper_bound = 0
    scale_out_adjustment                  = 50
    scale_in_metric_interval_upper_bound  = 0
    scale_in_adjustment                   = -50
  }

  assert {
    condition     = length(aws_appstream_fleet.appstream_fleet) == 1
    error_message = "Exactly one AppStream fleet should be planned."
  }

  assert {
    condition     = aws_appstream_stack.appstream_stack.name == "test-stack"
    error_message = "Stack name should match the supplied stack_name variable."
  }

  assert {
    condition     = length(aws_appautoscaling_target.appstream_target) == 1
    error_message = "Exactly one autoscaling target should be planned for the single fleet config."
  }
}

run "plan_homefolder_enabled" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    region                             = "eu-west-2"
    desired_instances                  = 1
    description                        = "Homefolder test fleet"
    idle_disconnect_timeout_in_seconds = 600
    disconnect_timeout_in_seconds      = 60
    display_name                       = "Homefolder Test Fleet"
    enable_default_internet_access     = false
    fleet_type                         = "ON_DEMAND"
    stream_view                        = "APP"
    instance_type                      = "stream.standard.small"
    max_user_duration_in_seconds       = 3600

    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
    security_group_ids = ["sg-12345678"]

    stack_name         = "homefolder-stack"
    stack_description  = "Homefolder stack"
    stack_display_name = "Homefolder Stack"
    enable_homefolder  = true

    associated_fleet = "fleet-home"
    fleet_configs = [
      {
        fleet_name      = "fleet-home"
        image_arn       = "arn:aws:appstream:eu-west-2:123456789012:image/test-image"
        min_capacity    = 1
        max_capacity    = 2
        scale_up_cron   = "cron(0 8 ? * MON-FRI *)"
        scale_down_cron = "cron(0 18 ? * MON-FRI *)"
        min_wh_capacity = 1
        max_wh_capacity = 2
      }
    ]

    scale_out_metric_interval_upper_bound = 0
    scale_out_adjustment                  = 50
    scale_in_metric_interval_upper_bound  = 0
    scale_in_adjustment                   = -50
  }

  assert {
    condition     = null_resource.manage_homefolder.triggers.enable_homefolder == "true"
    error_message = "Homefolder trigger should be true when enable_homefolder is true."
  }

  assert {
    condition     = aws_appstream_fleet_stack_association.this.fleet_name == "fleet-home"
    error_message = "Fleet association should point to the associated_fleet value."
  }
}

run "plan_multi_fleet_autoscaling" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    region                             = "eu-west-2"
    desired_instances                  = 2
    description                        = "Multi fleet test"
    idle_disconnect_timeout_in_seconds = 600
    disconnect_timeout_in_seconds      = 60
    display_name                       = "Multi Fleet"
    enable_default_internet_access     = false
    fleet_type                         = "ON_DEMAND"
    stream_view                        = "APP"
    instance_type                      = "stream.standard.small"
    max_user_duration_in_seconds       = 3600

    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
    security_group_ids = ["sg-12345678"]

    stack_name         = "multi-stack"
    stack_description  = "Multi stack"
    stack_display_name = "Multi Stack"
    enable_homefolder  = false

    associated_fleet = "fleet-b"
    fleet_configs = [
      {
        fleet_name      = "fleet-a"
        image_arn       = "arn:aws:appstream:eu-west-2:123456789012:image/test-image-a"
        min_capacity    = 1
        max_capacity    = 3
        scale_up_cron   = "cron(0 8 ? * MON-FRI *)"
        scale_down_cron = "cron(0 18 ? * MON-FRI *)"
        min_wh_capacity = 1
        max_wh_capacity = 2
      },
      {
        fleet_name      = "fleet-b"
        image_arn       = "arn:aws:appstream:eu-west-2:123456789012:image/test-image-b"
        min_capacity    = 2
        max_capacity    = 4
        scale_up_cron   = "cron(0 9 ? * MON-FRI *)"
        scale_down_cron = "cron(0 19 ? * MON-FRI *)"
        min_wh_capacity = 2
        max_wh_capacity = 4
      }
    ]

    scale_out_metric_interval_upper_bound = 0
    scale_out_adjustment                  = 50
    scale_in_metric_interval_upper_bound  = 0
    scale_in_adjustment                   = -50
  }

  assert {
    condition     = length(aws_appstream_fleet.appstream_fleet) == 2
    error_message = "Two fleets should be planned when two fleet_configs are supplied."
  }

  assert {
    condition     = length(aws_appautoscaling_policy.scale_out_policy) == 2
    error_message = "Two scale-out policies should be planned for two fleets."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.scale_in_alarm) == 2
    error_message = "Two scale-in alarms should be planned for two fleets."
  }
}

run "plan_extra_scale_out_policy_step_bounds" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    region                             = "eu-west-2"
    desired_instances                  = 1
    description                        = "Extra scale-out step bounds test"
    idle_disconnect_timeout_in_seconds = 600
    disconnect_timeout_in_seconds      = 60
    display_name                       = "Extra Scale Out Test"
    enable_default_internet_access     = false
    fleet_type                         = "ON_DEMAND"
    stream_view                        = "APP"
    instance_type                      = "stream.standard.small"
    max_user_duration_in_seconds       = 3600

    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
    security_group_ids = ["sg-12345678"]

    stack_name         = "extra-scale-out-stack"
    stack_description  = "Extra scale-out stack"
    stack_display_name = "Extra Scale Out Stack"
    enable_homefolder  = false

    associated_fleet = "fleet-extra"
    fleet_configs = [
      {
        fleet_name = "fleet-extra"
        image_arn  = "arn:aws:appstream:eu-west-2:123456789012:image/test-image"
        min_capacity = 10
        max_capacity = 40
        extra_scale_out_policies = [
          {
            name_suffix         = "scale-out-capacity-policy"
            metric_name         = "AvailableCapacity"
            comparison_operator = "LessThanOrEqualToThreshold"
            threshold           = 10
            scaling_adjustment  = 20
          },
          {
            name_suffix         = "scale-out-utilization-policy"
            metric_name         = "CapacityUtilization"
            comparison_operator = "GreaterThanOrEqualToThreshold"
            threshold           = 75
            scaling_adjustment  = 25
          },
        ]
      }
    ]

    scale_out_metric_interval_upper_bound = 0
    scale_out_adjustment                  = 50
    # Deliberately non-zero so the test proves less-than extra scale-out does not inherit scale-in bounds.
    scale_in_metric_interval_upper_bound  = -5
    scale_in_adjustment                   = -50
  }

  assert {
    condition = length(aws_appautoscaling_policy.extra_scale_out_policy) == 2
    error_message = "Two extra scale-out policies should be planned."
  }

  assert {
    condition = length(aws_cloudwatch_metric_alarm.extra_scale_out_alarm) == 2
    error_message = "Two extra scale-out alarms should be planned."
  }

  assert {
    condition = length([
      for step in tolist(aws_appautoscaling_policy.extra_scale_out_policy["fleet-extra/scale-out-capacity-policy"].step_scaling_policy_configuration[0].step_adjustment) :
      step
      if tostring(try(step.metric_interval_upper_bound, "")) == "0" && tostring(try(step.metric_interval_lower_bound, "")) == ""
    ]) == 1
    error_message = "Less-than extra scale-out must use upper bound 0 with no lower bound (independent of scale_in_metric_interval_upper_bound)."
  }

  assert {
    condition = length([
      for step in tolist(aws_appautoscaling_policy.extra_scale_out_policy["fleet-extra/scale-out-utilization-policy"].step_scaling_policy_configuration[0].step_adjustment) :
      step
      if tostring(try(step.metric_interval_lower_bound, "")) == "0" && tostring(try(step.metric_interval_upper_bound, "")) == ""
    ]) == 1
    error_message = "Greater-than extra scale-out must use lower bound 0 with no upper bound."
  }
}

run "plan_fleet_instance_role" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    region                             = "eu-west-2"
    desired_instances                  = 1
    description                        = "Fleet instance role test"
    idle_disconnect_timeout_in_seconds = 600
    disconnect_timeout_in_seconds      = 60
    display_name                       = "Fleet Instance Role Test"
    enable_default_internet_access     = false
    fleet_type                         = "ON_DEMAND"
    stream_view                        = "APP"
    instance_type                      = "stream.standard.small"
    max_user_duration_in_seconds       = 3600

    subnet_ids         = ["subnet-11111111", "subnet-22222222"]
    security_group_ids = ["sg-12345678"]

    stack_name         = "role-stack"
    stack_description  = "Role stack"
    stack_display_name = "Role Stack"
    enable_homefolder  = false

    associated_fleet = "fleet-role"
    fleet_configs = [
      {
        fleet_name      = "fleet-role"
        image_arn       = "arn:aws:appstream:eu-west-2:123456789012:image/test-image"
        min_capacity    = 1
        max_capacity    = 3
        scale_up_cron   = "cron(0 8 ? * MON-FRI *)"
        scale_down_cron = "cron(0 18 ? * MON-FRI *)"
        min_wh_capacity = 1
        max_wh_capacity = 2
      }
    ]

    scale_out_metric_interval_upper_bound = 0
    scale_out_adjustment                  = 50
    scale_in_metric_interval_upper_bound  = 0
    scale_in_adjustment                   = -50

    create_fleet_instance_role = true
    fleet_instance_role_name   = "cc-pam-apc-02-appstream-instance-role"
  }

  assert {
    condition     = length(aws_iam_role.fleet_instance) == 1
    error_message = "Fleet instance IAM role should be created when create_fleet_instance_role is true."
  }

  assert {
    condition     = aws_iam_role.fleet_instance[0].name == "cc-pam-apc-02-appstream-instance-role"
    error_message = "Fleet instance IAM role name should match the supplied fleet_instance_role_name."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.fleet_instance_cloudwatch_agent) == 1
    error_message = "CloudWatch agent policy should be attached to the fleet instance role."
  }
}
