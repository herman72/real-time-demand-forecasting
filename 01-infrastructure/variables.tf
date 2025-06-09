variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-north-1" # Stockholm is a good choice for Finland
}

variable "project_name" {
  description = "A unique name for the project, used to prefix resource names."
  type        = string
  default     = "demand-forecast"
}