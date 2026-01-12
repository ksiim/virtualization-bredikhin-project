resource "yandex_vpc_security_group" "sg_lb" {
  name       = "${var.project}-sg-lb"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTP"
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTPS"
  }

  ingress {
    protocol       = "TCP"
    port           = 30080
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    description    = "ALB healthchecks"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "All outbound"
  }
}

resource "yandex_vpc_security_group" "sg_app" {
  name       = "${var.project}-sg-app"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol          = "TCP"
    port              = var.app_port
    security_group_id = yandex_vpc_security_group.sg_lb.id
    description       = "From ALB"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.ssh_allowed_cidr]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = var.app_port
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    description    = "ALB healthchecks"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "All outbound"
  }
}

resource "yandex_vpc_security_group" "sg_db" {
  name       = "${var.project}-sg-db"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol          = "TCP"
    port              = 5432
    security_group_id = yandex_vpc_security_group.sg_app. id
    description       = "PostgreSQL from App"
  }

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.ssh_allowed_cidr]
    description    = "SSH"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "All outbound"
  }
}

resource "yandex_iam_service_account" "s3" {
  name = "${var.project}-s3-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "s3_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.s3.id}"
}

resource "yandex_iam_service_account_static_access_key" "s3_key" {
  service_account_id = yandex_iam_service_account.s3.id
  description        = "static key for object storage"
}

resource "yandex_storage_bucket" "bucket" {
  bucket = "${var.project}-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}
