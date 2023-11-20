terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

#Provider
provider "yandex" {
  token        = var.yc_token
  cloud_id     = var.yc_cloud_id
  folder_id    = var.yc_folder_id
}


#Network
resource "yandex_vpc_network" "network1" {
  name = "network1"
}
# Создание подсетей
resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}
resource "yandex_vpc_subnet" "subnet2" {
  name = "subnet2"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.2.0/24"]
}

#WebServers
#webserver1
resource "yandex_compute_instance" "webserver1" {
  name = "webserver1"
  zone = "ru-central1-a"
    resources{
    cores = 2
    memory = 2
    core_fraction = 20
  }
  boot_disk{
    initialize_params {
      image_id = "fd8ffhod48n84f4hnskb"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#webserver2
resource "yandex_compute_instance" "webserver2" {
  name = "webserver2"
  zone = "ru-central1-b"
  resources{
    cores = 2
    memory = 2
    core_fraction = 20
  }
  boot_disk{
    initialize_params {
      image_id = "fd8ffhod48n84f4hnskb"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#prometeus
resource "yandex_compute_instance" "prometheus"{
  name = "prometheus"
  zone = "ru-central1-a"
  resources{
    cores = 2
    memory = 2
    core_fraction = 20
  }
  boot_disk{
    initialize_params {
      image_id = "fd8ffhod48n84f4hnskb"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#grafana
resource "yandex_compute_instance" "grafana"{
  name = "grafana"
  zone = "ru-central1-a"
  resources{
    cores = 2
    memory = 2
    core_fraction = 20  
  }
  boot_disk{
    initialize_params {
    image_id =  "fd8ffhod48n84f4hnskb"
    size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }  
}

#elastic
resource "yandex_compute_instance" "elast"{
  name = "elast"
  zone = "ru-central1-a"
  resources{
    cores = 2
    memory = 4
    core_fraction = 20
  }
  boot_disk{
    initialize_params {
      image_id = "fd8ffhod48n84f4hnskb"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#kibana
resource "yandex_compute_instance" "kibana"{
  name = "kibana"
  zone = "ru-central1-a"
  resources{
    cores = 4
    memory = 8
    core_fraction = 20
  }
  boot_disk{
    initialize_params {
      image_id = "fd8ffhod48n84f4hnskb"
      size = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#target
resource "yandex_lb_target_group" "targettesting"{
  name = "targettesting"
  target {
    subnet_id = "${yandex_vpc_subnet.subnet1.id}"
    address = "${yandex_compute_instance.webserver1.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet2.id}"
    address = "${yandex_compute_instance.webserver2.network_interface.0.ip_address}"
  }
}

#balancer
resource "yandex_lb_network_load_balancer" "foo" {
  name = "my-network-load-balancer"
  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = "${yandex_lb_target_group.targettesting.id}"
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

#outputs
output "webserver1_ip_pub" {
  value = yandex_compute_instance.webserver1.network_interface.0.nat_ip_address
}
output "webserver2_ip_pub" {
  value = yandex_compute_instance.webserver2.network_interface.0.nat_ip_address
}
output "prometheus_ip_pub" {
  value = yandex_compute_instance.prometheus.network_interface.0.nat_ip_address
}
output "elastic_ip" {
  value = yandex_compute_instance.elast.network_interface.0.nat_ip_address
}
output "grafana_ip_pub" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}









