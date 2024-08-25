# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-west-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "public_subnet_cidr_block" {
  type        = string
  description = "Public subnet CIDR"
}

variable "private_subnet_1_cidr_block" {
  type        = string
  description = "Private subnet 1 CIDR"
}

variable "private_subnet_2_cidr_block" {
  type        = string
  description = "Private subnet 2 CIDR"
}
