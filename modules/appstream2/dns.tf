data "aws_vpc" "vpc" {
  count = var.attach_vpc_to_r53_profile ? 1 : 0
  id    = var.vpc_id
}

data "aws_route53profiles_profiles" "profiles" {
  count = var.attach_vpc_to_r53_profile ? 1 : 0
}

resource "aws_route53profiles_association" "default" {
  count       = var.attach_vpc_to_r53_profile ? 1 : 0
  name        = "core-cloud-r53-profile"
  profile_id  = data.aws_route53profiles_profiles.profiles[0][0].id
  resource_id = data.aws_vpc.vpc[0].id
}

