variable "appstream_security_group" {
  description = "Name of the AppStream security group"
  type        = string
}

variable "appstream_security_group_description" {
  description = "Description for the AppStream security group"
  type        = string
  default     = null
}

variable "appstream_vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "List of IPv4 CIDR blocks to allow inbound"
  type        = list(string)
  default     = []
}

variable "ingress_from_port" {
  description = "Start port for ingress rules"
  type        = number
  default     = 443
}

variable "ingress_to_port" {
  description = "End port for ingress rules"
  type        = number
  default     = 443
}

variable "ingress_protocol" {
  description = "IP protocol for ingress (e.g. \"tcp\")"
  type        = string
  default     = "tcp"
}

variable "egress_cidr_blocks" {
  description = "List of IPv4 CIDR blocks to allow outbound"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_protocol" {
  description = "IP protocol for egress (use \"-1\" for all)"
  type        = string
  default     = "-1"
}
