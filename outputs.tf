output "automq_byoc_env_id" {
  description = "This parameter is used to create resources within the environment. Additionally, all cloud resource names will incorporate this parameter as part of their names. This parameter supports only numbers, uppercase and lowercase English letters, and hyphens. It must start with a letter and is limited to a length of 32 characters."
  value       = var.automq_byoc_env_id
}

output "automq_byoc_endpoint" {
  description = "The endpoint for the AutoMQ environment console. Users can set this endpoint to the AutoMQ Terraform Provider to manage resources through Terraform. Additionally, users can access this endpoint via web browser, log in, and manage resources within the environment using the WebUI."
  value       = "http://${google_compute_address.web_ip.address}:8080"
}

output "automq_byoc_initial_username" {
  description = "The initial username for the AutoMQ environment console. It has the `EnvironmentAdmin` role permissions. This account is used to log in to the environment, create ServiceAccounts, and manage other resources. For detailed information about environment members, please refer to the [documentation](https://docs.automq.com/automq-cloud/manage-identities-and-access/member-accounts)."
  value       = "admin"
}

output "automq_byoc_initial_password" {
  description = "The initial password for the AutoMQ environment console. This account is used to log in to the environment, create ServiceAccounts, and manage other resources. For detailed information about environment members, please refer to the [documentation](https://docs.automq.com/automq-cloud/manage-identities-and-access/member-accounts)."
  value       = google_compute_instance.automq_byoc_console.instance_id
}

output "automq_byoc_vpc_id" {
  description = "The VPC ID for the AutoMQ environment deployment."
  value       = local.automq_byoc_vpc_name
}

output "automq_byoc_instance_id" {
  description = "The EC2 instance id for AutoMQ Console."
  value       = google_compute_instance.automq_byoc_console.instance_id
}

output "automq_byoc_google_service_account" {
  description = "The Google Service Account for the AutoMQ environment deployment."
  value       = google_service_account.automq_byoc_sa.email
}

output "automq_byoc_console_subnet" {
  description = "The subnet for the AutoMQ environment console."
  value       = local.automq_byoc_env_console_public_subnet_self_link
}
