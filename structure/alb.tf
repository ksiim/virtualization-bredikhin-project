resource "yandex_alb_target_group" "tg" {
  name = "${var.project}-tg"

  target {
    subnet_id  = yandex_vpc_subnet.a.id
    ip_address = yandex_compute_instance.app1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.b.id
    ip_address = yandex_compute_instance.app2.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "bg" {
  name = "${var.project}-bg"

  http_backend {
    name             = "app"
    weight           = 1
    port             = var.app_port
    target_group_ids = [yandex_alb_target_group.tg.id]

    healthcheck {
      timeout  = "1s"
      interval = "2s"

      http_healthcheck {
        path = "/api/v1/health"
      }
    }
  }
}

resource "yandex_alb_http_router" "router" {
  name = "${var.project}-router"
}

resource "yandex_alb_virtual_host" "vh" {
  name           = "${var.project}-vh"
  http_router_id = yandex_alb_http_router.router.id

  route {
    name = "route-all"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb" {
  name               = "${var.project}-alb"
  network_id         = yandex_vpc_network.net.id
  security_group_ids = [yandex_vpc_security_group.sg_lb.id]

  allocation_policy {
    location { zone_id = "ru-central1-a" subnet_id = yandex_vpc_subnet.a.id }
    location { zone_id = "ru-central1-b" subnet_id = yandex_vpc_subnet.b.id }
  }

  listener {
    name = "http-80"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}
