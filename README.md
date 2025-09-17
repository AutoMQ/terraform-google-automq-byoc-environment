
# GCP AutoMQ BYOC Environment Terraform module
![Preview](https://img.shields.io/badge/Lifecycle_Stage-Preview-blue?style=flat&logoColor=8A3BE2&labelColor=rgba)

This module is designed for deploying the AutoMQ BYOC (Bring Your Own Cloud) environment using the GCP Provider within a GCP cloud environment.

Upon completion of the installation, the module will output the endpoint of the AutoMQ BYOC environment along with the initial username and password. Users can manage the resources within the environment through the following two methods:

- **Using the Web UI to manage resources**: This method allows users to manage instances, topics, ACLs, and other resources through a web-ui.
- **Using Terraform to manage resources**: This method requires users to access the AutoMQ BYOC environment via a web browser for the first time to create a Service Account. Subsequently, users can manage resources within the environment using the Service Account's Access Key and the AutoMQ Terraform Provider.

For managing instances, topics, and other resources within the AutoMQ BYOC environment using the AutoMQ Terraform Provider, please refer to the [documentation](https://registry.terraform.io/providers/AutoMQ/automq/latest/docs).

# Module Usage
Use this module to install the AutoMQ BYOC environment, supporting two modes:

- **Create a new VPC**: Recommended only for POC or other testing scenarios. In this mode, the user only needs to specify the region, and resources including VPC, Endpoint, Security Group, GCS Bucket, etc., will be created. After testing, all resources can be destroyed with one click.
- **Using an existing VPC**: Recommended for production environments. In this mode, the user needs to provide a VPC, subnet, and GCS Bucket that meet the requirements. AutoMQ will deploy the BYOC environment console to the user-specified subnet.

## Quick Start

1. **Install Terraform**

   Ensure Terraform is installed on your system. You can download it from the [Terraform website](https://www.terraform.io/downloads.html).

2. **Configure GCP Credentials**

   Make sure your GCP CLI is configured with the necessary credentials. You can configure it using the following command:

   ```bash
   gcloud auth application-default login
   ```

3. **Create Terraform Configuration File**

   Create a file named `main.tf` in your working directory and add the following content:

### Create a new VPC

```terraform
module "automq-byoc" {
  source = "AutoMQ/automq-byoc-environment/google"

  # Set the identifier for the environment to be installed.
  automq_byoc_env_id                       = "example" 

  cloud_provider_region                    = "asia-southeast1"  
  cloud_provider_zone                      = "asia-southeast1-a"
  cloud_project_id                         = "xxxxxxxx"
}

# Necessary outputs
output "automq_byoc_env_id" {
  value = module.automq-byoc.automq_byoc_env_id
}

output "automq_byoc_endpoint" {
  value = module.automq-byoc.automq_byoc_endpoint
}

output "automq_byoc_initial_username" {
  value = module.automq-byoc.automq_byoc_initial_username
}

output "automq_byoc_initial_password" {
  value = module.automq-byoc.automq_byoc_initial_password
}

output "automq_byoc_vpc_id" {
  value = module.automq-byoc.automq_byoc_vpc_id
}

output "automq_byoc_instance_id" {
  value = module.automq-byoc.automq_byoc_instance_id
}

output "automq_byoc_google_service_account" {
  value = module.automq-byoc.automq_byoc_google_service_account
}
```

### Using an existing VPC

To install the AutoMQ BYOC environment using an existing VPC, ensure your existing VPC meets the necessary requirements. You can find the detailed requirements in the [Prepare VPC Documents](https://docs.automq.com/automq-cloud/getting-started/install-byoc-environment/gcp/prepare-vpc).

```terraform
module "automq-byoc" {
  source = "AutoMQ/automq-byoc-environment/google"

  # Set the identifier for the environment to be installed.
  automq_byoc_env_id                       = "example" 

  # Set the target regionId of gcp
  cloud_provider_region                    = "asia-southeast1"  
  cloud_provider_zone                      = "asia-southeast1-a"
  cloud_project_id                         = "xxxxx"

  create_new_vpc                           = false   
  existing_vpc_name                        = "xxxxx-network"
  existing_subnet_name                     = "xxxxx-subnetwork"

  automq_byoc_data_bucket_name             = "bucker-data-xxxx"
  automq_byoc_ops_bucket_name              = "bucker-ops-xxxx"
  automq_byoc_machine_type                 = "e2-standard-2"
  automq_byoc_default_deploy_type          = "k8s"
}

# Necessary outputs
output "automq_byoc_env_id" {
  value = module.automq-byoc.automq_byoc_env_id
}

output "automq_byoc_endpoint" {
  value = module.automq-byoc.automq_byoc_endpoint
}

output "automq_byoc_initial_username" {
  value = module.automq-byoc.automq_byoc_initial_username
}

output "automq_byoc_initial_password" {
  value = module.automq-byoc.automq_byoc_initial_password
}

output "automq_byoc_vpc_id" {
  value = module.automq-byoc.automq_byoc_vpc_id
}

output "automq_byoc_instance_id" {
  value = module.automq-byoc.automq_byoc_instance_id
}

output "automq_byoc_google_service_account" {
  value = module.automq-byoc.automq_byoc_google_service_account
}
```

4. **Initialize Terraform**

   Run the following command to initialize Terraform:

   ```bash
   terraform init
   ```

5. **Apply Terraform Configuration**

   Run the following command to apply the Terraform configuration and create the resources:

   ```bash
   terraform apply
   ```

   Confirm the action by typing `yes` when prompted.

6. **Retrieve Outputs**

   After the deployment is complete, run the following command to retrieve the outputs:

   ```bash
   terraform output
   ```

   This will display the AutoMQ environment console endpoint, initial username, and initial password.

7. **Access AutoMQ Environment Console**

   Use the `automq_byoc_endpoint`, `automq_byoc_initial_username`, and `automq_byoc_initial_password` to access the AutoMQ environment console via a web browser.

8. **Manage Resources**

   You can manage resources within the AutoMQ BYOC environment using the Web UI or Terraform. For more details, refer to the [documentation](https://docs.automq.com/automq-cloud/manage-identities-and-access/member-accounts).

9. **Clean Up Resources**

   If you no longer need the resources, you can destroy them by running:

   ```bash
   terraform destroy
   ```

   Confirm the action by typing `yes` when prompted.

# Helpful Links/Information

* [Report Bugs](https://github.com/AutoMQ/terraform-google-automq-byoc-environment/issues)

* [AutoMQ Cloud Documents](https://docs.automq.com/automq-cloud/overview)

* [Request Features](https://automq66.feishu.cn/share/base/form/shrcn7qXbb5aKiYbKqbJtPlGWXc)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement_google) | >= 5, < 7 |
| <a name="requirement_random"></a> [random](#requirement_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider_random) | >= 3.0.0 |
| <a name="provider_google"></a> [google](#provider_google) | >= 5, < 7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_address.web_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_attached_disk.data_volume_attachment](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_disk.data_volume](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_firewall.allow_googleapis_ipv4](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.automq_byoc_console_sg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.subnet_allow-internal](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.automq_byoc_console](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.automq_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.route_ipv4_googleapi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_route.route_ipv4_googleapi_additional](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.automq_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.gke_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_project_iam_binding.automq_byoc_compute_sa_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_binding.automq_byoc_dns_sa_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_binding.automq_byoc_gke_sa_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_binding.automq_byoc_resource_sa_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_binding.automq_byoc_storage_sa_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_binding.gke_permission_binding0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_binding) | resource |
| [google_project_iam_custom_role.automq_byoc_compute_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.automq_byoc_dns_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.automq_byoc_gke_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.automq_byoc_resource_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.automq_byoc_storage_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_service_account.automq_byoc_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.automq_byoc_ops_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_tags_location_tag_binding.compute_instance_env_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_location_tag_binding) | resource |
| [google_tags_location_tag_binding.compute_instance_vendor_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_location_tag_binding) | resource |
| [google_tags_tag_key.automqEnvKey](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key) | resource |
| [google_tags_tag_key.automqVendorKey](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_key) | resource |
| [google_tags_tag_value.automqEnvValue](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | resource |
| [google_tags_tag_value.automqVendorValue](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | resource |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_storage_bucket.ops_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_bucket) | data source |

The module defaults to the AutoMQ BYOC console image `projects/automq-public/global/images/automq-control-center-prod-7-7-4-x86-64`. To use a different image, set `use_custom_image = true` and provide the full self link via `automq_byoc_env_console_image`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_project_id"></a> [cloud_project_id](#input_cloud_project_id) | The Google Cloud Project ID where resources will be created | `string` | n/a | yes |
| <a name="input_automq_byoc_env_id"></a> [automq_byoc_env_id](#input_automq_byoc_env_id) | The unique identifier of the AutoMQ environment. This parameter is used to create resources within the environment. Additionally, all cloud resource names will incorporate this parameter as part of their names. This parameter supports only numbers, uppercase and lowercase English letters, and hyphens. It must start with a letter and is limited to a length of 32 characters. | `string` | n/a | yes |
| <a name="input_cloud_provider_region"></a> [cloud_provider_region](#input_cloud_provider_region) | Set the Google Cloud region. AutoMQ will deploy to this region. | `string` | n/a | yes |
| <a name="input_cloud_provider_zone"></a> [cloud_provider_zone](#input_cloud_provider_zone) | Set the Google Cloud zone. AutoMQ will deploy to this zone. | `string` | n/a | yes |
| <a name="input_create_new_vpc"></a> [create_new_vpc](#input_create_new_vpc) | This setting determines whether to create a new VPC. If set to true, a new VPC will be automatically created, which is recommended only for POC scenarios. For production scenarios using AutoMQ, you should provide the VPC where the current Kafka application resides. | `bool` | `true` | no |
| <a name="input_existing_vpc_name"></a> [existing_vpc_name](#input_existing_vpc_name) | When the create_new_vpc parameter is set to false, specify an existing VPC name where AutoMQ will be deployed. | `string` | `""` | no |
| <a name="input_existing_subnet_name"></a> [existing_subnet_name](#input_existing_subnet_name) | When the create_new_vpc parameter is set to false, specify an existing subnet name for deploying the AutoMQ BYOC environment console. | `string` | `""` | no |
| <a name="input_automq_byoc_env_console_cidr"></a> [automq_byoc_env_console_cidr](#input_automq_byoc_env_console_cidr) | Set CIDR block to restrict the source IP address range for accessing the AutoMQ environment console. If not set, the default is 0.0.0.0/0. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_automq_byoc_ops_bucket_name"></a> [automq_byoc_ops_bucket_name](#input_automq_byoc_ops_bucket_name) | Set the existed GCS bucket used to store AutoMQ system logs and metrics data for system monitoring and alerts. If this parameter is not set, a new GCS bucket will be automatically created. This Bucket does not contain any application business data. | `string` | `""` | no |
| <a name="input_automq_byoc_machine_type"></a> [automq_byoc_machine_type](#input_automq_byoc_machine_type) | Set the Compute Engine machine type; this parameter is used only for deploying the AutoMQ environment console. You need to provide a machine type with at least 2 cores and 8 GB of memory. | `string` | `"e2-standard-2"` | no |
| <a name="input_use_custom_image"></a> [use_custom_image](#input_use_custom_image) | Set to true to use a custom image for the AutoMQ environment console and provide automq_byoc_env_console_image. | `bool` | `false` | no |
| <a name="input_automq_byoc_env_console_image"></a> [automq_byoc_env_console_image](#input_automq_byoc_env_console_image) | The custom image self link used when use_custom_image is true. | `string` | `""` | no |
| <a name="input_ssh_public_key"></a> [ssh_public_key](#input_ssh_public_key) | Set the SSH public key for the AutoMQ environment console. The public key is used to access the AutoMQ environment console via SSH. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_automq_byoc_env_id"></a> [automq_byoc_env_id](#output_automq_byoc_env_id) | This parameter is used to create resources within the environment. Additionally, all cloud resource names will incorporate this parameter as part of their names. This parameter supports only numbers, uppercase and lowercase English letters, and hyphens. It must start with a letter and is limited to a length of 32 characters. |
| <a name="output_automq_byoc_endpoint"></a> [automq_byoc_endpoint](#output_automq_byoc_endpoint) | The endpoint for the AutoMQ environment console. Users can set this endpoint to the AutoMQ Terraform Provider to manage resources through Terraform. Additionally, users can access this endpoint via web browser, log in, and manage resources within the environment using the WebUI. |
| <a name="output_automq_byoc_initial_username"></a> [automq_byoc_initial_username](#output_automq_byoc_initial_username) | The initial username for the AutoMQ environment console. It has the `EnvironmentAdmin` role permissions. This account is used to log in to the environment, create ServiceAccounts, and manage other resources. For detailed information about environment members, please refer to the [documentation](https://docs.automq.com/automq-cloud/manage-identities-and-access/member-accounts). |
| <a name="output_automq_byoc_initial_password"></a> [automq_byoc_initial_password](#output_automq_byoc_initial_password) | The initial password for the AutoMQ environment console. This account is used to log in to the environment, create ServiceAccounts, and manage other resources. For detailed information about environment members, please refer to the [documentation](https://docs.automq.com/automq-cloud/manage-identities-and-access/member-accounts). |
| <a name="output_automq_byoc_vpc_id"></a> [automq_byoc_vpc_id](#output_automq_byoc_vpc_id) | The VPC ID for the AutoMQ environment deployment. |
| <a name="output_automq_byoc_instance_id"></a> [automq_byoc_instance_id](#output_automq_byoc_instance_id) | The EC2 instance id for AutoMQ Console. |
| <a name="output_automq_byoc_google_service_account"></a> [automq_byoc_google_service_account](#output_automq_byoc_google_service_account) | The Google Service Account for the AutoMQ environment deployment. |
<!-- END_TF_DOCS -->
