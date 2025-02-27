variable "cloud_project_id" {
  description = "The Google Cloud Project ID where resources will be created"
  type        = string
}

variable "automq_byoc_env_id" {
  description = "The unique identifier of the AutoMQ environment. This parameter is used to create resources within the environment. Additionally, all cloud resource names will incorporate this parameter as part of their names. This parameter supports only numbers, uppercase and lowercase English letters, and hyphens. It must start with a letter and is limited to a length of 32 characters."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,31}$", var.automq_byoc_env_id)) && !can(regex("_", var.automq_byoc_env_id))
    error_message = "The environment_id must start with a letter, can only contain alphanumeric characters and hyphens, cannot contain underscores, and must be 32 characters or fewer."
  }
}

variable "cloud_provider_region" {
  description = "Set the Google Cloud region. AutoMQ will deploy to this region."
  type        = string
}

variable "cloud_provider_zone" {
  description = "Set the Google Cloud zone. AutoMQ will deploy to this zone."
  type        = string
}

variable "create_new_vpc" {
  description = "This setting determines whether to create a new VPC. If set to true, a new VPC will be automatically created, which is recommended only for POC scenarios. For production scenarios using AutoMQ, you should provide the VPC where the current Kafka application resides."
  type        = bool
  default     = true
}

variable "existing_vpc_name" {
  description = "When the create_new_vpc parameter is set to false, specify an existing VPC name where AutoMQ will be deployed."
  type        = string
  default     = ""
}

variable "existing_subnet_name" {
  description = "When the create_new_vpc parameter is set to false, specify an existing subnet name for deploying the AutoMQ BYOC environment console."
  type        = string
  default     = ""
}

variable "automq_byoc_env_console_cidr" {
  description = "Set CIDR block to restrict the source IP address range for accessing the AutoMQ environment console. If not set, the default is 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

variable "automq_byoc_ops_bucket_name" {
  description = "Set the existed GCS bucket used to store AutoMQ system logs and metrics data for system monitoring and alerts. If this parameter is not set, a new GCS bucket will be automatically created. This Bucket does not contain any application business data."
  type        = string
  default     = ""
}

variable "automq_byoc_machine_type" {
  description = "Set the Compute Engine machine type; this parameter is used only for deploying the AutoMQ environment console. You need to provide a machine type with at least 2 cores and 8 GB of memory."
  type        = string
  default     = "e2-standard-2" # GCP equivalent of t3.large
}

variable "automq_byoc_env_version" {
  description = "Set the version for the AutoMQ BYOC environment console. It is recommended to keep the default value, which is the latest version."
  type        = string
  default     = "1.4.0"
}

variable "use_custom_image" {
  description = "The parameter defaults to false, which means a specific custom image is not specified. If you wish to use a custom image, set this parameter to true and specify the automq_byoc_env_console_image parameter."
  type        = bool
  default     = false
}

variable "automq_byoc_env_console_image" {
  description = "When the use_custom_image parameter is set to true, this parameter must be set with a custom image name to deploy the AutoMQ console."
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "Set the SSH public key for the AutoMQ environment console. The public key is used to access the AutoMQ environment console via SSH."
  type        = string
  default     = ""
}
