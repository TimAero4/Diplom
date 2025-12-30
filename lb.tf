# Target Group
resource "yandex_alb_target_group" "web_tg" {
  name      = "web-target-group-${var.flow}"
  folder_id = var.folder_id

  target {
    subnet_id = yandex_vpc_subnet.develop_a.id
    ip_address = yandex_compute_instance.web_1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.develop_b.id
    ip_address = yandex_compute_instance.web_2.network_interface.0.ip_address
  }
}

# Backend Group
resource "yandex_alb_backend_group" "web_bg" {
  name      = "web-backend-group-${var.flow}"
  folder_id = var.folder_id

  http_backend {
    name         = "web-backend"
    weight       = 1
    port         = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]
    
    healthcheck {
      timeout  = "1s"
      interval = "2s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "web_router" {
  name        = "web-router-${var.flow}"
  folder_id   = var.folder_id

  virtual_host {
    name      = "virtual-host"
    route {
      name = "main-route"
      http_route {
        http_route_action {
          backend_group_id = yandex_alb_backend_group.web_bg.id
          timeout          = "3s"
        }
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "web_balancer" {
  name        = "web-balancer-${var.flow}"
  folder_id   = var.folder_id
  network_id  = yandex_vpc_network.develop.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.develop_a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.develop_b.id
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  log_options {
    discard_rule {
      http_codes = ["200"]
      percentage = 50
    }
  }
}

# Output the balancer public IP
output "load_balancer_ip" {
  value = yandex_alb_load_balancer.web_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

