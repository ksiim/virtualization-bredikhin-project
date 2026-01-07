resource "yandex_vpc_security_group" "sg_lb" {
  name       = "${var.project}-sg-lb"
  network_id = yandex_vpc_network.net.id

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "public http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "ALB healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

resource "yandex_vpc_security_group" "sg_app" {
  name       = "${var.project}-sg-app"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol          = "TCP"
    description       = "from ALB to app"
    security_group_id = yandex_vpc_security_group.sg_lb.id
    port              = var.app_port
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = [var.ssh_allowed_cidr]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "sg_db" {
  name       = "${var.project}-sg-db"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol          = "TCP"
    description       = "postgres from app"
    security_group_id = yandex_vpc_security_group.sg_app.id
    port              = 5432
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = [var.ssh_allowed_cidr]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
