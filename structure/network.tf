resource "yandex_vpc_network" "net" {
  name = "${var.project}-net"
}

resource "yandex_vpc_subnet" "a" {
  name           = "${var.project}-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_subnet" "b" {
  name           = "${var.project}-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.129.0.0/24"]
}

resource "yandex_vpc_subnet" "d" {
  name           = "${var.project}-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.130.0.0/24"]
}
