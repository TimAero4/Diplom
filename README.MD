1.  Создать сервисный аккаунт в облаке. Выдать права editor
2.  Выпустить авторизованный ключ для этого аккаунта и скачать его по пути ~/.authorized_key.json . 
3.  Вписать в переменные cloud_id и folder_id в variables.tf
4.  Изменить ssh-ключ в файле cloud-init.yml (ssh-keygen -t ed25519). cp terraformrc ~/.terraformrc
5.  terraform init && terraform apply
6.  После создания инфраструктуры terraform output
7.  Также необходимо посмотреть адреса созданной инфраструктуры cat hosts.ini
8.  rm ~/.ssh/known_hosts. Выполнить playbook ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.ini test.yml
9.  Далее устанавливаем zabbix-server командой ansible-playbook -i hosts.ini zabbix-server.yml  
10. После устанавливаем zabix-agent командой ansible-playbook -i hosts.ini zabbix-agent.yml 
11. Следующим шагом настраиваем dashboard при помощи команды  ansible-playbook -i hosts.ini zabbix-dashboards.yml 


Для проверки того, что инфраструктура настроена верно, необходимо после 
1. выполения playbook ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.ini test.yml выполнить
   curl http://<web-balancer_ip> в результате можно увидеть как при разном количестве запросов меняется 
   web-1 и web-2 в ответ на curl
2. 
3.
4.   

https://www.jeffgeerling.com/blog/2022/using-ansible-playbook-ssh-bastion-jump-host

Настройка доступа по ssh через ssh config: 
~/.ssh/config
```
Host external_bastion_ipv4  #адрес вашего бастиона
   User user

Host 10.0.*
        ProxyJump external_bastion_ipv4 
        User user

Host *.ru-central1.internal
        ProxyJump external_bastion_ipv4 
        User user

```


Или более простой для понимания, но менее удобный для частого применения: ssh -J jump_server remote_server
Также реализован ssh -L 8080:zabbix_internal:80 user@bastion_external

