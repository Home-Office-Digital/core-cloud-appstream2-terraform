data "aws_iam_policy_document" "fleet_instance_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["appstream.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fleet_instance" {
  count = var.create_fleet_instance_role && var.fleet_instance_role_arn == null ? 1 : 0

  name               = var.fleet_instance_role_name
  assume_role_policy = data.aws_iam_policy_document.fleet_instance_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fleet_instance_cloudwatch_agent" {
  count = var.create_fleet_instance_role && var.fleet_instance_role_arn == null ? 1 : 0

  role       = aws_iam_role.fleet_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

locals {
  fleet_instance_role_arn = var.fleet_instance_role_arn != null ? var.fleet_instance_role_arn : try(aws_iam_role.fleet_instance[0].arn, null)
}
