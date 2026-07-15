resource "aws_appstream_fleet" "appstream_fleet" {
  for_each = { for config in var.fleet_configs : config.fleet_name => config }
  name     = each.value.fleet_name

  compute_capacity {
    desired_instances = coalesce(try(each.value.desired_instances, null), var.desired_instances)
  }

  description                        = var.description
  idle_disconnect_timeout_in_seconds = var.idle_disconnect_timeout_in_seconds
  disconnect_timeout_in_seconds      = var.disconnect_timeout_in_seconds
  display_name                       = var.display_name
  enable_default_internet_access     = var.enable_default_internet_access
  fleet_type                         = var.fleet_type
  stream_view                        = var.stream_view
  image_arn                          = each.value.image_arn
  instance_type                      = var.instance_type
  max_user_duration_in_seconds       = var.max_user_duration_in_seconds
  iam_role_arn                       = local.fleet_instance_role_arn

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }
  
}

resource "aws_appstream_stack" "appstream_stack" {
  name         = var.stack_name
  description  = var.stack_description
  display_name = var.stack_display_name

  dynamic "user_settings" {
    for_each = var.user_settings
    content {
      action     = user_settings.value.action
      permission = user_settings.value.permission
    }
  }

  application_settings {
    enabled = false
  }
}

resource "null_resource" "manage_homefolder" {
  provisioner "local-exec" {
    interpreter = ["bash", "-lc"]

    command = <<EOT
    if [ "${var.enable_homefolder}" = "true" ]; then
      echo "Enabling HOMEFOLDER storage connector..."
      aws appstream update-stack \
        --name "${aws_appstream_stack.appstream_stack.name}" \
        --region "${var.region}" \
        --storage-connectors "ConnectorType=HOMEFOLDERS"
    else
      echo "Disabling HOMEFOLDER storage connector..."
      aws appstream update-stack \
        --name "${aws_appstream_stack.appstream_stack.name}" \
        --region "${var.region}" \
        --delete-storage-connectors
    fi
    EOT
  }

  triggers = {
    enable_homefolder = var.enable_homefolder
  }

  depends_on = [aws_appstream_stack.appstream_stack]
}

resource "null_resource" "wait_for_fleet_running" {
  triggers = {
    associated_fleet = var.associated_fleet
    stack_name       = var.stack_name
  }

  provisioner "local-exec" {
    # run under bash -l so /usr/local/bin/aws is on PATH
    interpreter = ["bash", "-lc"]

    command = "${path.module}/check_fleet_status.sh ${var.associated_fleet} ${var.region}"
  }

  depends_on = [aws_appstream_fleet.appstream_fleet]
}

resource "aws_appstream_fleet_stack_association" "this" {
  fleet_name = aws_appstream_fleet.appstream_fleet[var.associated_fleet].name
  stack_name = aws_appstream_stack.appstream_stack.name

  # Fleet/stack references above are sufficient for create ordering.
  # Do not depends_on null_resource.wait_for_fleet_running — replacing that
  # null_resource would otherwise force this association to be recreated.
}

resource "aws_appautoscaling_target" "appstream_target" {
  for_each           = { for fleet in var.fleet_configs : fleet.fleet_name => fleet }
  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "fleet/${each.value.fleet_name}"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  service_namespace  = "appstream"

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_scheduled_action" "appstream_scale_up" {
  for_each = {
    for fleet in var.fleet_configs : fleet.fleet_name => fleet
    if try(fleet.scale_up_cron, null) != null && length(coalesce(try(fleet.scheduled_actions, null), [])) == 0
  }
  name               = "${each.value.fleet_name}-scale-up"
  service_namespace  = "appstream"
  resource_id        = "fleet/${each.value.fleet_name}"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  schedule           = each.value.scale_up_cron

  scalable_target_action {
    min_capacity = coalesce(try(each.value.min_wh_capacity, null), each.value.min_capacity)
    max_capacity = coalesce(try(each.value.max_wh_capacity, null), each.value.max_capacity)
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_scheduled_action" "appstream_scale_down" {
  for_each = {
    for fleet in var.fleet_configs : fleet.fleet_name => fleet
    if try(fleet.scale_down_cron, null) != null && length(coalesce(try(fleet.scheduled_actions, null), [])) == 0
  }
  name               = "${each.value.fleet_name}-scale-down"
  service_namespace  = "appstream"
  resource_id        = "fleet/${each.value.fleet_name}"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  schedule           = each.value.scale_down_cron

  scalable_target_action {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_scheduled_action" "scheduled" {
  for_each = {
    for item in flatten([
      for fleet in var.fleet_configs : [
        for action in coalesce(try(fleet.scheduled_actions, null), []) : {
          key        = "${fleet.fleet_name}/${action.name}"
          fleet_name = fleet.fleet_name
          action     = action
        }
        if coalesce(try(fleet.manage_extended_autoscaling, null), true)
      ]
    ]) : item.key => item
  }

  name               = "${each.value.fleet_name}-${each.value.action.name}"
  service_namespace  = "appstream"
  resource_id        = "fleet/${each.value.fleet_name}"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  schedule           = each.value.action.schedule

  scalable_target_action {
    min_capacity = each.value.action.min_capacity
    max_capacity = each.value.action.max_capacity
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_policy" "extra_scale_out_policy" {
  for_each = {
    for item in flatten([
      for fleet in var.fleet_configs : [
        for policy in coalesce(try(fleet.extra_scale_out_policies, null), []) : {
          key        = "${fleet.fleet_name}/${policy.name_suffix}"
          fleet_name = fleet.fleet_name
          fleet      = fleet
          policy     = policy
        }
        if coalesce(try(fleet.manage_extended_autoscaling, null), true)
      ]
    ]) : item.key => item
  }

  name               = "${each.value.fleet_name}-${each.value.policy.name_suffix}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.appstream_target[each.value.fleet_name].resource_id
  scalable_dimension = aws_appautoscaling_target.appstream_target[each.value.fleet_name].scalable_dimension
  service_namespace  = aws_appautoscaling_target.appstream_target[each.value.fleet_name].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = coalesce(try(each.value.policy.cooldown, null), coalesce(try(each.value.fleet.scale_out_cooldown, null), 120))
    metric_aggregation_type = coalesce(try(each.value.policy.metric_aggregation_type, null), coalesce(try(each.value.fleet.metric_aggregation_type, null), "Maximum"))

    step_adjustment {
      metric_interval_lower_bound = var.scale_out_metric_interval_upper_bound
      scaling_adjustment          = each.value.policy.scaling_adjustment
    }
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_cloudwatch_metric_alarm" "extra_scale_out_alarm" {
  for_each = {
    for item in flatten([
      for fleet in var.fleet_configs : [
        for policy in coalesce(try(fleet.extra_scale_out_policies, null), []) : {
          key        = "${fleet.fleet_name}/${policy.name_suffix}"
          fleet_name = fleet.fleet_name
          fleet      = fleet
          policy     = policy
        }
        if coalesce(try(fleet.manage_extended_autoscaling, null), true)
      ]
    ]) : item.key => item
  }

  alarm_name          = "${each.value.fleet_name}-${replace(each.value.policy.name_suffix, "-policy", "")}"
  comparison_operator = each.value.policy.comparison_operator
  evaluation_periods  = coalesce(try(each.value.policy.evaluation_periods, null), 1)
  metric_name         = each.value.policy.metric_name
  namespace           = "AWS/AppStream"
  period              = coalesce(try(each.value.policy.period, null), 60)
  statistic           = coalesce(try(each.value.policy.statistic, null), coalesce(try(each.value.fleet.scale_out_alarm_statistic, null), "Maximum"))
  threshold           = each.value.policy.threshold

  dimensions = {
    Fleet = each.value.fleet_name
  }

  alarm_actions = [aws_appautoscaling_policy.extra_scale_out_policy[each.key].arn]

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_policy" "scale_out_policy" {
  for_each           = { for fleet in var.fleet_configs : fleet.fleet_name => fleet }
  name               = "${each.value.fleet_name}-scale-out-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.appstream_target[each.value.fleet_name].resource_id
  scalable_dimension = aws_appautoscaling_target.appstream_target[each.value.fleet_name].scalable_dimension
  service_namespace  = aws_appautoscaling_target.appstream_target[each.value.fleet_name].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = coalesce(try(each.value.scale_out_cooldown, null), 120)
    metric_aggregation_type = coalesce(try(each.value.metric_aggregation_type, null), "Maximum")

    step_adjustment {
      metric_interval_lower_bound = var.scale_out_metric_interval_upper_bound
      scaling_adjustment          = coalesce(try(each.value.scale_out_adjustment, null), var.scale_out_adjustment)
    }
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_appautoscaling_policy" "scale_in_policy" {
  for_each           = { for fleet in var.fleet_configs : fleet.fleet_name => fleet }
  name               = "${each.value.fleet_name}-scale-in-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.appstream_target[each.value.fleet_name].resource_id
  scalable_dimension = aws_appautoscaling_target.appstream_target[each.value.fleet_name].scalable_dimension
  service_namespace  = aws_appautoscaling_target.appstream_target[each.value.fleet_name].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "PercentChangeInCapacity"
    cooldown                = coalesce(try(each.value.scale_in_cooldown, null), 120)
    metric_aggregation_type = coalesce(try(each.value.metric_aggregation_type, null), "Maximum")

    step_adjustment {
      metric_interval_lower_bound = coalesce(try(each.value.scale_in_step_use_upper_bound, null), false) ? null : var.scale_in_metric_interval_upper_bound
      metric_interval_upper_bound = coalesce(try(each.value.scale_in_step_use_upper_bound, null), false) ? coalesce(try(each.value.scale_in_metric_interval_upper_bound, null), var.scale_in_metric_interval_upper_bound) : null
      scaling_adjustment          = coalesce(try(each.value.scale_in_adjustment, null), var.scale_in_adjustment)
    }
  }

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  for_each           = { for fleet in var.fleet_configs : fleet.fleet_name => fleet }
  alarm_name         = "${each.value.fleet_name}-insufficient-capacity-error"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "InsufficientCapacityError"
  namespace           = "AWS/AppStream"
  period              = 60
  statistic           = coalesce(try(each.value.scale_out_alarm_statistic, null), "Maximum")
  threshold           = 0

  dimensions = {
    Fleet = each.value.fleet_name
  }

  alarm_description = try(each.value.scale_out_alarm_description, null) != null ? each.value.scale_out_alarm_description : "Alarm when out of capacity is > 0"
  alarm_actions     = [aws_appautoscaling_policy.scale_out_policy[each.value.fleet_name].arn]

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  for_each           = { for fleet in var.fleet_configs : fleet.fleet_name => fleet }
  alarm_name         = "${each.value.fleet_name}-low-capacity-utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = coalesce(try(each.value.scale_in_evaluation_periods, null), 1)
  metric_name         = "CapacityUtilization"
  namespace           = "AWS/AppStream"
  period              = coalesce(try(each.value.scale_in_alarm_period, null), 60)
  statistic           = coalesce(try(each.value.scale_in_alarm_statistic, null), "Maximum")
  threshold           = coalesce(try(each.value.scale_in_alarm_threshold, null), 25)

  dimensions = {
    Fleet = each.value.fleet_name
  }

  alarm_description = try(each.value.scale_in_alarm_description, null) != null ? each.value.scale_in_alarm_description : "Alarm when Capacity Utilization <= ${coalesce(try(each.value.scale_in_alarm_threshold, null), 25)} percent"
  alarm_actions     = [aws_appautoscaling_policy.scale_in_policy[each.value.fleet_name].arn]

  depends_on = [
    aws_appstream_fleet.appstream_fleet
  ]
}

resource "null_resource" "create-appstream-usage-report" {
  depends_on = [aws_appstream_stack.appstream_stack]
  provisioner "local-exec" {
    interpreter = ["bash", "-lc"]
    command = "aws appstream create-usage-report-subscription"
  }
}