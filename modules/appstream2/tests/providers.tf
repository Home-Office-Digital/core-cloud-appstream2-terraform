terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.no_default_tags]
    }
    null = {
      source = "hashicorp/null"
    }
  }
}
