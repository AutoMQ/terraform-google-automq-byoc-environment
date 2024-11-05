resource "google_compute_instance" "automq_byoc_console" {
  name         = lower(replace("automq-byoc-console-${var.automq_byoc_env_id}", "_", "-"))
  machine_type = var.automq_byoc_machine_type
  zone         = var.cloud_provider_zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.console_image.self_link
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = local.automq_byoc_vpc_name
    subnetwork = local.automq_byoc_env_console_public_subnet_name
    access_config {
      nat_ip = google_compute_address.web_ip.address
    }
  }

  service_account {
    email  = google_service_account.automq_byoc_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/tpls/userdata.tpl", {
    automq_data_bucket         = local.automq_data_bucket,
    automq_ops_bucket          = local.automq_ops_bucket,
    instance_service_account   = google_service_account.automq_byoc_sa.account_id,
    environment_id             = var.automq_byoc_env_id
    instance_security_group_id = google_compute_firewall.automq_byoc_console_sg.id
    instance_dns               = google_dns_managed_zone.private_dns_zone.id
    deploy_type                = var.automq_byoc_default_deploy_type
  })

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = "${var.automq_byoc_env_id}"
  }
}

resource "google_compute_disk" "data_volume" {
  name = lower(replace("automq-data-volume-${var.automq_byoc_env_id}", "_", "-"))
  zone = var.cloud_provider_zone
  size = 20
  type = "pd-balanced"

  labels = {
    automq_vendor         = "automq"
    automq_environment_id = var.automq_byoc_env_id
  }
}

resource "google_compute_attached_disk" "data_volume_attachment" {
  instance    = google_compute_instance.automq_byoc_console.name
  zone        = var.cloud_provider_zone
  disk        = google_compute_disk.data_volume.name
  device_name = "data-volume-attachment-${var.automq_byoc_env_id}"
}
