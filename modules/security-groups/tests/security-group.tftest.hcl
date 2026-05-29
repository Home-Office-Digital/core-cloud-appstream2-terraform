provider "aws" {
  alias  = "test"
  region = "eu-west-2"

  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

run "plan_security_group_with_rules" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    appstream_security_group = "appstream-test-sg"
    appstream_vpc_id         = "vpc-12345678"
    ingress_cidr_blocks      = ["10.0.0.0/24", "10.0.1.0/24"]
    egress_cidr_blocks       = ["0.0.0.0/0"]
    ingress_from_port        = 443
    ingress_to_port          = 443
    ingress_protocol         = "tcp"
    egress_protocol          = "-1"
  }

  assert {
    condition     = aws_security_group.appstream_security_group.name == "appstream-test-sg"
    error_message = "Security group name should match the supplied variable value."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.allow_inbound) == 2
    error_message = "Exactly two ingress rules should be planned from ingress_cidr_blocks."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.allow_outbound) == 1
    error_message = "Exactly one egress rule should be planned from egress_cidr_blocks."
  }
}

run "plan_security_group_with_defaults" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    appstream_security_group = "appstream-default-sg"
    appstream_vpc_id         = "vpc-12345678"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.allow_inbound) == 0
    error_message = "No ingress rules should be planned when ingress_cidr_blocks is empty."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.allow_outbound) == 1
    error_message = "One default egress rule should be planned when egress_cidr_blocks is omitted."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.allow_outbound["0.0.0.0/0"].ip_protocol == "-1"
    error_message = "Default egress protocol should allow all traffic."
  }
}

run "plan_security_group_custom_port_rules" {
  command = plan

  module {
    source = "../"
  }

  providers = {
    aws = aws.test
  }

  variables {
    appstream_security_group = "appstream-custom-port-sg"
    appstream_vpc_id         = "vpc-12345678"
    ingress_cidr_blocks      = ["10.10.0.0/24"]
    ingress_from_port        = 3389
    ingress_to_port          = 3389
    ingress_protocol         = "tcp"
    egress_cidr_blocks       = ["10.20.0.0/24", "10.30.0.0/24"]
    egress_protocol          = "tcp"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.allow_inbound["10.10.0.0/24"].from_port == 3389
    error_message = "Ingress from_port should match custom port input."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.allow_inbound["10.10.0.0/24"].to_port == 3389
    error_message = "Ingress to_port should match custom port input."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.allow_outbound) == 2
    error_message = "Two egress rules should be planned for two egress CIDR blocks."
  }
}
