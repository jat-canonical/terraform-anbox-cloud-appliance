variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "instance_type" {
  type    = string
  default = "g5g.xlarge"
}

variable "ua_token" {
  type     = string
  nullable = false
}

variable "channel" {
  type    = string
  default = "latest/stable"
}

variable "architecture" {
  type    = string
  default = "arm64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Valid values are: arm64, amd64."
  }
}

variable "ssh_import_ids" {
  type        = list(string)
  default     = []
  description = "List of ssh launchpad or github ids to import"
}

variable "dashboard_login_email_id" {
  type    = string
  default = ""
}
