Отказоустойчивая инфраструктруа для сайта, включающая мониторинг, сбор логов и резервное копирование основных данных.
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
12. В части ELK используется Elastic и Kibana на elastic web-server и filebeats для сбора логов. На сервере elastic необходимо
разместить docker_compose.yml и filebeat.yml.j2, запустить Elastic и Kibana при помощи sudo docker compose up -d
13. Установку fобраза filebeat на web-1 и web-2 лучше всего произвести при помощи docker pull elastic/filebeat:8.11.1
14. Запуск контейнера необходимо призвести при помощи docker run -d --name=filebeat --user=root --volume="/var/log/nginx:/var/log/nginx:ro" --volume="$(pwd)/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro" elastic/filebeat:8.11.1
15. Далее для инициализации в Kibana необходимо произвести  docker exec filebeat filebeat setup на web-1 и web-2.

Для проверки того, что инфраструктура настроена верно, необходимо после 
1. выполения playbook ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.ini test.yml выполнить
   curl http://web-balancer_ipv4 в результате можно увидеть как при разном количестве запросов меняется 
   web-1 и web-2 в ответ на curl
2. Для проверки Zabbix и Dashboards необходимо ssh -N -o ExitOnForwardFailure=yes -J user@ ipv4_bastion-L 8081:127.0.0.1:80 user@ipv4_zabbix_server
3. Далее в браузере с localhost  http://127.0.0.1:8081/zabbix/ войти в Zabbix и в Monitoring → Hosts проверить состояние хостов.
4. Проверку Elastic и Kibana можно осуществить при помощи прсмотра инофрмации в браузере http://localhost:9200 http://localhost:5601
5. Проверка после установки filebeat должна быть docker exec filebeat filebeat test config (вернуть должно Config OK)
6. Также проверка docker exec filebeat filebeat test output (должна вывести elasticsearch: http://ip_v4_elastic:9200... далее OK по всем параметрам)

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

