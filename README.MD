1. Создать сервисный аккаунт в облаке. Выдать права editor
2. Выпустить авторизованный ключ для этого аккаунта и скачать его по пути ~/.authorized_key.json . 
3. Вписать в переменные cloud_id и folder_id в variables.tf
4. Изменить ssh-ключ в файле cloud-init.yml (ssh-keygen -t ed25519). cp terraformrc ~/.terraformrc
5. terraform init && terraform apply
6. rm ~/.ssh/known_hosts. Выполнить playbook ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.ini test.yml

https://www.jeffgeerling.com/blog/2022/using-ansible-playbook-ssh-bastion-jump-host

Настройка доступа по ssh через ssh config: 
~/.ssh/config
```
Host 89.169.142.236  #адрес вашего бастиона
   User user

Host 10.0.*
        ProxyJump 89.169.142.236
        User user

Host *.ru-central1.internal
        ProxyJump 89.169.142.236
        User user

```

Или более простой для понимания, но менее удобный для частого применения: ssh -J <jump server> <remote server>

## load_balancer_ip = "158.160.170.83"
## bastion external_ip = 158.160.109.246 internal_ip = 10.0.1.34
## zabbix-1 external_ip = 158.160.117.47 internal_ip = 10.0.1.13
## web-1 internal_ip = 10.0.1.31
## web-2 internal_ip = 10.0.2.26
## elastic-1 internal_ip = 10.0.2.29