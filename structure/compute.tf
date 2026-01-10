data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

resource "random_password" "project_secret" {
  length  = 64
  special = false
}

locals {
  superuser_email    = "admin@example.com"
  superuser_password = "adminpass"
}

resource "yandex_compute_disk" "db_data" {
  name = "${var.project}-db-disk"
  size = var.db_disk_gb
  type = "network-ssd"
  zone = "ru-central1-a"
}

resource "yandex_compute_instance" "db" {
  name = "${var.project}-db"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.db_data.id
    auto_delete = false
    mode        = "READ_WRITE"
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg_db.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/db.yaml.tpl", {
      ssh_user = var.ssh_user
      db_name  = var.db_name
      db_user  = var.db_user
      db_pass  = var.db_pass
    })
  }
}

locals {
  db_private_ip = yandex_compute_instance.db.network_interface[0].ip_address
}

resource "yandex_compute_instance" "app1" {
  name = "${var.project}-app1"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg_app.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/app.yaml.tpl", {
      ssh_user           = var.ssh_user
      project            = var.project
      git_repo           = var.git_repo
      git_branch         = var.git_branch
      project_secret     = random_password.project_secret.result
      superuser_email    = local.superuser_email
      superuser_password = local.superuser_password

      db_host = local.db_private_ip
      db_name = var.db_name
      db_user = var.db_user
      db_pass = var.db_pass

      s3_access_key_id     = yandex_iam_service_account_static_access_key.s3_key.access_key
      s3_secret_access_key = yandex_iam_service_account_static_access_key.s3_key.secret_key
      bucket_name          = yandex_storage_bucket.bucket.bucket
    })
  }

  depends_on = [yandex_compute_instance.db]
}

resource "yandex_compute_instance" "app2" {
  name = "${var.project}-app2"
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg_app.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/app.yaml.tpl", {
      ssh_user           = var.ssh_user
      project            = var.project
      git_repo           = var.git_repo
      git_branch         = var.git_branch
      project_secret     = random_password.project_secret.result
      superuser_email    = local.superuser_email
      superuser_password = local.superuser_password

      db_host = local.db_private_ip
      db_name = var.db_name
      db_user = var.db_user
      db_pass = var.db_pass

      s3_access_key_id     = yandex_iam_service_account_static_access_key.s3_key.access_key
      s3_secret_access_key = yandex_iam_service_account_static_access_key.s3_key.secret_key
      bucket_name          = yandex_storage_bucket.bucket.bucket
    })
  }

  depends_on = [yandex_compute_instance.db]
}

