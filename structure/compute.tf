data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
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

  resources { cores = 2 memory = 2 }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.db_data.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg_db.id]
  }

  metadata = {
    ssh-keys  = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/db.yaml.tpl", {
      ssh_user    = var.ssh_user
      git_repo    = var.git_repo
      git_branch  = var.git_branch
    })
  }
}

resource "yandex_compute_instance" "app1" {
  name = "${var.project}-app1"
  zone = "ru-central1-a"

  resources { cores = 2 memory = 2 }

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
    ssh-keys  = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/app.yaml.tpl", {
      ssh_user   = var.ssh_user
      git_repo   = var.git_repo
      git_branch = var.git_branch
      db_ip      = yandex_compute_instance.db.network_interface[0].ip_address
      db_user    = var.db_user
      db_pass    = var.db_pass
      db_name    = var.db_name
      app_port   = var.app_port
    })
  }
}

resource "yandex_compute_instance" "app2" {
  name = "${var.project}-app2"
  zone = "ru-central1-b"

  resources { cores = 2 memory = 2 }

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
    ssh-keys  = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init/app.yaml.tpl", {
      ssh_user   = var.ssh_user
      git_repo   = var.git_repo
      git_branch = var.git_branch
      db_ip      = yandex_compute_instance.db.network_interface[0].ip_address
      db_user    = var.db_user
      db_pass    = var.db_pass
      db_name    = var.db_name
      app_port   = var.app_port
    })
  }
}
