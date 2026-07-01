# Only resolve Route53 profile data when both inputs are provided.
# This keeps default plans/tests from requiring live AWS API access.
data "aws_vpc" "vpc" {
  count = var.route53_profile_name != "" && var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

data "aws_route53profiles_profiles" "profiles" {
  count = var.route53_profile_name != "" && var.vpc_id != "" ? 1 : 0
}

locals {
  route53_association_enabled = var.route53_profile_name != "" && var.vpc_id != ""
  matched_profile = local.route53_association_enabled ? one([
    for p in data.aws_route53profiles_profiles.profiles[0].profiles : p
    if p.name == var.route53_profile_name
  ]) : null
}

resource "aws_route53profiles_association" "default" {
  provider = aws.no_default_tags

  count       = local.route53_association_enabled ? 1 : 0
  name        = var.route53_profile_name
  profile_id  = local.matched_profile.id
  resource_id = data.aws_vpc.vpc[0].id
}