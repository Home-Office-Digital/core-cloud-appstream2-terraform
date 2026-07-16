resource "aws_security_group" "appstream_security_group" {
  #checkov:skip=CKV2_AWS_5:Attached to aws_appstream_fleet via security_group_ids in the companion fleet module (separate Terragrunt stack).
  name        = var.appstream_security_group
  description = coalesce(var.appstream_security_group_description, "AppStream fleet security group for ${var.appstream_security_group}")
  vpc_id      = var.appstream_vpc_id
}

# Ingress rules driven by ingress_cidr_blocks list
resource "aws_vpc_security_group_ingress_rule" "allow_inbound" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.appstream_security_group.id
  cidr_ipv4         = each.key
  from_port         = var.ingress_from_port
  to_port           = var.ingress_to_port
  ip_protocol       = var.ingress_protocol
  description       = "Allow inbound ${var.ingress_protocol} ports ${var.ingress_from_port}-${var.ingress_to_port} from ${each.key}"
}

# Egress rules driven by egress_cidr_blocks list
resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  for_each = toset(var.egress_cidr_blocks)

  security_group_id = aws_security_group.appstream_security_group.id
  cidr_ipv4         = each.key
  ip_protocol       = var.egress_protocol
  description       = "Allow outbound ${var.egress_protocol} traffic to ${each.key}"
}
