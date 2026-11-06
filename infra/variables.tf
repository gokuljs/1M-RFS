variable "aws_region" {
  description = "AWS Region in which to create this experiment."
  type        = string
}

variable "project_name" {
  description = "Short prefix for resource names and tags."
  type        = string
  default     = "rfs-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.project_name))
    error_message = "Use 3–20 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "app_revision" {
  description = "Full Git commit SHA to deploy from the public application repository."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.app_revision))
    error_message = "Use a full 40-character lowercase Git commit SHA, not a branch or tag."
  }
}

variable "app_repository" {
  description = "Public GitHub repository; private repository credentials must not go in user data."
  type        = string
  default     = "https://github.com/gokuljs/1M-RFS.git"

  validation {
    condition     = can(regex("^https://github[.]com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+[.]git$", var.app_repository))
    error_message = "Use a public GitHub HTTPS clone URL ending in .git, with no embedded credentials."
  }
}

variable "app_framework" {
  description = "Database-free application to deploy. The restored Fastify experiment needs separate database setup."
  type        = string
  default     = "cpeak"

  validation {
    condition     = contains(["cpeak", "express"], var.app_framework)
    error_message = "Choose cpeak (port 3000) or express (port 3001)."
  }
}

variable "node_version" {
  description = "Exact Node.js release; default is the latest LTS verified on 2026-11-06."
  type        = string
  default     = "26.13.0"

  validation {
    condition     = can(regex("^[0-9]+[.][0-9]+[.][0-9]+$", var.node_version))
    error_message = "Pin an exact Node.js version without the v prefix."
  }
}

variable "pm2_version" {
  description = "Exact PM2 release, applied consistently to every instance."
  type        = string
  default     = "7.1.2"

  validation {
    condition     = can(regex("^[0-9]+[.][0-9]+[.][0-9]+$", var.pm2_version))
    error_message = "Pin an exact PM2 version."
  }
}

variable "ami_id" {
  description = "Optional pinned Amazon Linux 2023 x86_64 AMI; otherwise resolve AWS's current regional AL2023 AMI at plan time."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "x86_64 burstable EC2 instance type for this experiment."
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t(2|3|3a)[.](micro|small|medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Use an x86_64 T2, T3, or T3a type; this bootstrap installs the Linux x64 Node binary."
  }
}

variable "cpu_credit_mode" {
  description = "standard caps CPU at baseline after credits run out; unlimited can incur extra CPU charges."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credit_mode)
    error_message = "Choose standard or unlimited."
  }
}

variable "min_instances" {
  description = "Minimum running instances; use at least 2 if the deployment must survive losing one instance."
  type        = number
  default     = 1

  validation {
    condition     = var.min_instances >= 1 && floor(var.min_instances) == var.min_instances
    error_message = "Keep at least one instance running; use an integer."
  }
}

variable "desired_instances" {
  description = "Initial capacity. After creation, the scaling policies own desired capacity."
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Upper bound for demand-driven scaling. Instance refresh may temporarily launch extra instances."
  type        = number
  default     = 3

  validation {
    condition     = var.max_instances >= 1 && floor(var.max_instances) == var.max_instances
    error_message = "Use a positive integer."
  }
}

variable "cpu_target_percent" {
  description = "Experimental CPU target, not a measured capacity claim. Tune using representative traffic and CPU credits."
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target_percent > 0 && var.cpu_target_percent <= 90
    error_message = "Choose a CPU target above 0 and at most 90 percent."
  }
}

variable "target_requests_per_minute" {
  description = "Optional measured ALB requests-per-target per minute target; null leaves request-based scaling disabled."
  type        = number
  default     = null

  validation {
    condition     = var.target_requests_per_minute == null ? true : var.target_requests_per_minute > 0
    error_message = "Use a positive measured requests-per-minute target, or null."
  }
}

variable "instance_warmup_seconds" {
  description = "Time for a newly launched instance to stabilize before contributing to scaling metrics."
  type        = number
  default     = 300

  validation {
    condition     = var.instance_warmup_seconds >= 60 && floor(var.instance_warmup_seconds) == var.instance_warmup_seconds
    error_message = "Use a whole number of seconds, at least 60."
  }
}

variable "vpc_cidr" {
  description = "Dedicated VPC; two /20 subnets are derived from the default /16."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(regex("/(1[6-9]|2[0-3])$", var.vpc_cidr))
    error_message = "Use an IPv4 CIDR with prefix /16 through /23, leaving room for ALB subnets."
  }
}

variable "allowed_client_cidrs" {
  description = "IPv4 ranges allowed to reach the ALB. Restrict to your test client IPs when appropriate."
  type        = set(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_client_cidrs) > 0 && alltrue([for cidr in var.allowed_client_cidrs : can(cidrnetmask(cidr))])
    error_message = "Provide at least one valid IPv4 CIDR."
  }
}

variable "certificate_arn" {
  description = "Optional existing ACM certificate in the same Region; enables HTTPS and redirects HTTP to HTTPS."
  type        = string
  default     = null
}
