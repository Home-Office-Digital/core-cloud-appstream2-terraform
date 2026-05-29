data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route53profiles_profiles" "profiles" {}

locals {
  matched_profile = one([
    for p in data.aws_route53profiles_profiles.profiles.profiles : p
    if p.name == var.route53_profile_name
  ])
}

resource "aws_route53profiles_association" "default" {
  count       = var.route53_profile_name != "" ? 1 : 0
  name        = var.route53_profile_name
  profile_id  = local.matched_profile.id
  resource_id = data.aws_vpc.vpc.id
}