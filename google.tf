provider "google" {
  project = var.cloud_project_id
  region  = var.cloud_provider_region
}

locals {
  automq_byoc_vpc_name                       = var.create_new_vpc ? google_compute_network.automq_network[0].name : var.existing_vpc_name
  automq_byoc_env_console_public_subnet_name = var.create_new_vpc ? google_compute_subnetwork.automq_subnetwork[0].name : var.existing_subnet_name
  automq_data_bucket                         = var.automq_byoc_data_bucket_name == "" ? google_storage_bucket.automq_byoc_data_bucket[0].name : var.automq_byoc_data_bucket_name
  automq_ops_bucket                          = var.automq_byoc_ops_bucket_name == "" ? google_storage_bucket.automq_byoc_ops_bucket[0].name : var.automq_byoc_ops_bucket_name

  automq_vendor_tag_key   = "automqVendor"
  automq_vendor_tag_value = "automq"

  automq_env_tag_key   = "automqEnvironmentId"
  automq_env_tag_value = var.automq_byoc_env_id
}

data "google_project" "project" {
  project_id = var.cloud_project_id
}

resource "google_tags_tag_key" "automqVendorKey" {
  parent     = "projects/${var.cloud_project_id}"
  short_name = "${local.automq_vendor_tag_key}-${var.automq_byoc_env_id}"
}

resource "google_tags_tag_value" "automqVendorValue" {
  parent     = "tagKeys/${google_tags_tag_key.automqVendorKey.name}"
  short_name = local.automq_vendor_tag_value
}

resource "google_tags_tag_key" "automqEnvKey" {
  parent     = "projects/${var.cloud_project_id}"
  short_name = "${local.automq_env_tag_key}-${var.automq_byoc_env_id}"
}

resource "google_tags_tag_value" "automqEnvValue" {
  parent     = "tagKeys/${google_tags_tag_key.automqEnvKey.name}"
  short_name = local.automq_env_tag_value
}

# Create object storage bucket if not provided
resource "google_storage_bucket" "automq_byoc_data_bucket" {
  count = var.automq_byoc_data_bucket_name == "" ? 1 : 0

  name          = "automq-data-${var.automq_byoc_env_id}"
  location      = var.cloud_provider_region
  force_destroy = true

  uniform_bucket_level_access = true

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

resource "google_storage_bucket" "automq_byoc_ops_bucket" {
  count = var.automq_byoc_data_bucket_name == "" ? 1 : 0

  name          = "automq-ops-${var.automq_byoc_env_id}"
  location      = var.cloud_provider_region
  force_destroy = true

  uniform_bucket_level_access = true

  soft_delete_policy {
    retention_duration_seconds = 0
  }

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

resource "google_storage_bucket_iam_binding" "automq_data_storage_permission_binding" {
  bucket = local.automq_data_bucket
  role   = google_project_iam_custom_role.automq_byoc_storage_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_storage_bucket_iam_binding" "automq_ops_storage_permission_binding" {
  bucket = local.automq_ops_bucket
  role   = google_project_iam_custom_role.automq_byoc_storage_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

# VPC Network
resource "google_compute_network" "automq_network" {
  count = var.create_new_vpc ? 1 : 0

  name = lower(replace("automq_byoc_vpc_${var.automq_byoc_env_id}", "_", "-"))
  project = var.cloud_project_id

  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "automq_subnetwork" {
  count = var.create_new_vpc ? 1 : 0

  name = "console-subnet-${var.automq_byoc_env_id}"

  ip_cidr_range = "10.0.0.0/20"
  region        = var.cloud_provider_region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.automq_network[0].id
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  count = var.create_new_vpc ? 1 : 0

  name = "gke-subnet-${var.automq_byoc_env_id}"

  ip_cidr_range = "10.1.0.0/20"
  region        = var.cloud_provider_region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.automq_network[0].id
}

# Service Account
resource "google_service_account" "automq_byoc_sa" {
  account_id   = "automq-byoc-sa-${var.automq_byoc_env_id}"
  display_name = "AutoMQ BYOC ${var.automq_byoc_env_id} Service Account"
  project      = var.cloud_project_id
}

resource "google_project_iam_custom_role" "automq_byoc_storage_role" {
  role_id     = replace("automq_byoc_storage_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} Storage Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} Storage Role"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.setRetention",
    "storage.objects.update",
    "storage.multipartUploads.create",
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_compute_role" {
  role_id     = replace("automq_byoc_compute_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} Compute Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} Compute Role"
  permissions = [
    "compute.instances.get",
    "compute.disks.get",
    "compute.instances.list",
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get"
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_dns_role" {
  role_id     = replace("automq_byoc_dns_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} DNS Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} DNS Role"
  permissions = [
    "dns.changes.create",
    "dns.managedZones.get",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
  ]
}

resource "google_project_iam_custom_role" "automq_byoc_resource_role" {
  role_id     = replace("automq_byoc_resource_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} ResourceManager Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} ResourceManager Role"
  permissions = [
    "resourcemanager.projects.get",
  ]
}


resource "google_project_iam_custom_role" "automq_byoc_gke_role" {
  role_id     = replace("automq_byoc_gke_sa_role_${var.automq_byoc_env_id}", "-", "_")
  title       = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role"
  description = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role"
  permissions = [
    "container.apiServices.create",
    "container.apiServices.delete",
    "container.apiServices.get",
    "container.apiServices.getStatus",
    "container.apiServices.list",
    "container.apiServices.update",
    "container.apiServices.updateStatus",
    "container.auditSinks.create",
    "container.auditSinks.delete",
    "container.auditSinks.get",
    "container.nodes.list",
    "container.networkPolicies.get",
    "container.networkPolicies.create",
    "container.clusters.connect",
    "container.clusters.create",
    "container.clusters.createTagBinding",
    "container.clusters.delete",
    "container.clusters.deleteTagBinding",
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusters.list",
    "container.clusters.listEffectiveTags",
    "container.clusters.listTagBindings",
    "container.clusters.update",
    "container.configMaps.create",
    "container.configMaps.delete",
    "container.configMaps.get",
    "container.configMaps.list",
    "container.configMaps.update",
    "container.namespaces.create",
    "container.namespaces.delete",
    "container.namespaces.finalize",
    "container.namespaces.get",
    "container.namespaces.getStatus",
    "container.namespaces.list",
    "container.namespaces.update",
    "container.namespaces.updateStatus",
    "container.pods.attach",
    "container.pods.create",
    "container.pods.delete",
    "container.pods.evict",
    "container.pods.exec",
    "container.pods.get",
    "container.pods.getLogs",
    "container.pods.getStatus",
    "container.pods.list",
    "container.pods.portForward",
    "container.pods.proxy",
    "container.pods.update",
    "container.pods.updateStatus",
    "container.secrets.create",
    "container.secrets.delete",
    "container.secrets.get",
    "container.secrets.list",
    "container.secrets.update",
    "container.services.create",
    "container.services.delete",
    "container.services.get",
    "container.services.getStatus",
    "container.services.list",
    "container.services.proxy",
    "container.services.update",
    "container.services.updateStatus",
    "container.statefulSets.create",
    "container.statefulSets.delete",
    "container.statefulSets.get",
    "container.statefulSets.getScale",
    "container.statefulSets.getStatus",
    "container.statefulSets.list",
    "container.statefulSets.update",
    "container.statefulSets.updateScale",
    "container.statefulSets.updateStatus"
  ]
}

resource "google_project_iam_binding" "automq_byoc_dns_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_dns_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_resource_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_resource_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_compute_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_compute_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
}

resource "google_project_iam_binding" "automq_byoc_gke_sa_binding" {
  project = var.cloud_project_id
  role    = google_project_iam_custom_role.automq_byoc_gke_role.name
  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}"
  ]
  condition {
    title      = "AutoMQ BYOC ${var.automq_byoc_env_id} GKE Role Condition"
    expression = "resource.matchTag(\"${var.cloud_project_id}/automqAssigned\", \"automq\")"
  }
}

resource "google_project_iam_binding" "gke_permission_binding0" {
  project = var.cloud_project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding1" {
  project = var.cloud_project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding2" {
  project = var.cloud_project_id
  role    = "roles/monitoring.viewer"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding3" {
  project = var.cloud_project_id
  role    = "roles/stackdriver.resourceMetadata.writer"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding4" {
  project = var.cloud_project_id
  role    = "roles/autoscaling.metricsWriter"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding5" {
  project = var.cloud_project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

resource "google_project_iam_binding" "gke_permission_binding6" {
  project = var.cloud_project_id
  role    = "roles/resourcemanager.tagUser"

  members = [
    "serviceAccount:${google_service_account.automq_byoc_sa.email}",
  ]
}

# Firewall rules
resource "google_compute_firewall" "automq_byoc_console_sg" {
  name    = "automq-byoc-console-${var.automq_byoc_env_id}"
  network = local.automq_byoc_vpc_name
  project = var.cloud_project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = [var.automq_byoc_env_console_cidr]
}

# Static IP
resource "google_compute_address" "web_ip" {
  name    = lower(replace("automq_web_ip_${var.automq_byoc_env_id}", "_", "-"))
  project = var.cloud_project_id
  region  = var.cloud_provider_region
}


locals {
  console_image_name = var.use_custom_image ? var.automq_byoc_env_console_image : "automq-control-center-prod-${var.automq_byoc_env_version}-x86_64"
}
data "google_compute_image" "console_image" {
  name = local.console_image_name
}

data "google_compute_network" "vpc" {
  depends_on = [ google_compute_network.automq_network ]
  name       = local.automq_byoc_vpc_name
}


resource "google_dns_managed_zone" "private_dns_zone" {
  name     = "automq-byoc-private-zone-${var.automq_byoc_env_id}"
  dns_name = "${var.automq_byoc_env_id}.automq.private."

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }

  visibility = "private"

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "google_dns_managed_zone" "private_googleapis" {
  name        = "private-googleapis"
  dns_name    = "googleapis.com."
  description = "Private zone for Google APIs"

  visibility = "private"
  private_visibility_config {
    networks {
      network_url = data.google_compute_network.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "wildcard_googleapis_cname" {
  name         = "*.googleapis.com."
  managed_zone = google_dns_managed_zone.private_googleapis.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}

resource "google_dns_record_set" "private_googleapis_ipv4" {
  name         = "private.googleapis.com."
  managed_zone = google_dns_managed_zone.private_googleapis.name
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_compute_route" "route_ipv4_googleapi" {
  name             = "route-to-googleapis-ipv4"
  network          = data.google_compute_network.vpc.id
  dest_range       = "199.36.153.8/30"
  next_hop_gateway = "global/gateways/default-internet-gateway"

  priority = 90
}

resource "google_compute_route" "route_ipv4_googleapi_additional" {
  name             = "route-to-googleapis-ipv4-additional"
  network          = data.google_compute_network.vpc.id
  dest_range       = "34.126.0.0/18"
  next_hop_gateway = "global/gateways/default-internet-gateway"

  priority = 90
}

resource "google_compute_firewall" "allow_googleapis_ipv4" {
  name    = "allow-outbound-googleapis-ipv4"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = [
    "199.36.153.8/30",
    "34.126.0.0/18"
  ]

  direction = "EGRESS"
}



# Create GKE cluster and node pool
resource "google_container_cluster" "automq_gke_cluster" {
  name = "gke-cluster-${var.automq_byoc_env_id}"

  location                 = var.cloud_provider_zone
  enable_l4_ilb_subsetting = true

  network    = local.automq_byoc_vpc_name
  subnetwork = google_compute_subnetwork.gke_subnetwork[0].id

  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "STABLE"
  }

  addons_config {
    dns_cache_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  datapath_provider = "ADVANCED_DATAPATH"

  remove_default_node_pool = true
  initial_node_count       = 1

  # Set `deletion_protection` to `true` will ensure that one cannot
  # accidentally delete this instance by use of Terraform.
  deletion_protection = false
}


resource "google_tags_tag_key" "automqAssignedKey" {
  parent     = "projects/${var.cloud_project_id}"
  short_name = "automqAssigned"
}

resource "google_tags_tag_value" "automqAssignedValue" {
  parent     = "tagKeys/${google_tags_tag_key.automqEnvKey.name}"
  short_name = "automq"
}


resource "google_container_node_pool" "automq_gke_node_pool" {
  name       = "node-pool-${var.automq_byoc_env_id}"
  location   = var.cloud_provider_region
  cluster    = google_container_cluster.automq_gke_cluster.id
  node_count = 1

  node_config {
    machine_type = "n2d-standard-4"

    disk_type    = "pd-ssd"
    disk_size_gb = 20

    workload_metadata_config {
      mode = "GCE_METADATA" // GKE_METADATA for workload identity
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.automq_byoc_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    total_min_node_count = 3
    total_max_node_count = 9
    location_policy      = "BALANCED"
  }

  management {
    auto_repair  = false
    auto_upgrade = true
  }
}

resource "google_compute_router" "router" {
  project = var.cloud_project_id
  name    = "nat-router-${var.automq_byoc_env_id}"
  network = local.automq_byoc_vpc_name
  region  = var.cloud_provider_region
}

resource "google_compute_router" "vpc_router" {
  name    = "vpc-router-${var.automq_byoc_env_id}"
  network = data.google_compute_network.vpc.id
  region  = var.cloud_provider_region
}

resource "google_compute_router_nat" "vpc_nat" {
  name   = "vpc-nat-gateway-${var.automq_byoc_env_id}"
  router = google_compute_router.vpc_router.name
  region = var.cloud_provider_region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke_subnetwork[0].name
    source_ip_ranges_to_nat = [google_compute_subnetwork.gke_subnetwork[0].ip_cidr_range]
  }
}

