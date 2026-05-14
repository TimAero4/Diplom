
#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}

resource "yandex_compute_instance" "web_1" {
  name        = "web-1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

resource "yandex_compute_instance" "web_2" {
  name        = "web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = var.test.cores
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_sg.id]
  }
}

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix-1"
  hostname    = "zabbix-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 20
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.bastion.id]
  }
}

resource "yandex_compute_instance" "elastic" {
  name        = "elastic-1"
  hostname    = "elastic-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 20
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.LAN.id]
  }
}


resource "local_file" "inventory" {
  content  = <<-EOT
  [bastion]
  bastion ansible_host=${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

  [webservers]
  web-1 ansible_host=${yandex_compute_instance.web_1.network_interface.0.ip_address}
  web-2 ansible_host=${yandex_compute_instance.web_2.network_interface.0.ip_address}
  
   
  [zabbix]
  # Используем внутренний IP, так как внешний убран
  zabbix-1 ansible_host=${yandex_compute_instance.zabbix.network_interface.0.ip_address}
  
  [elastic]
  elastic-1 ansible_host=${yandex_compute_instance.elastic.network_interface.0.ip_address}

  [all:vars]
  ansible_user=user
  # Добавляем внутренний IP Zabbix в переменные, чтобы плейбуки могли его использовать
  zabbix_ip=${yandex_compute_instance.zabbix.network_interface.0.ip_address}

  [webservers:vars]
  ansible_ssh_common_args='-o ProxyJump=user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}'
  
  [elastic:vars]
  ansible_ssh_common_args='-o ProxyJump=user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}'
  
  # Добавляем настройки ProxyJump для Zabbix
  [zabbix:vars]
  ansible_ssh_common_args='-o ProxyJump=user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}'
  
  EOT
  filename = "./hosts.ini"
}

locals {
  all_disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web_1.boot_disk[0].disk_id,
    yandex_compute_instance.web_2.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.elastic.boot_disk[0].disk_id
  ]
}

resource "yandex_compute_snapshot_schedule" "daily_snapshots" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 3 * * *"
  }

  snapshot_count = 7
  disk_ids        = local.all_disk_ids

  snapshot_spec {
    description = "Daily snapshots for diploma project"
  }
}

