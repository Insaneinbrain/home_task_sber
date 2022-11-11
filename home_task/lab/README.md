## Тестовое задание для Сберкорус.

### Задача

Тестовое задание — https://github.com/Ilasasds/home_task

* Скопировать репозиторий с вагрант файлами для создания машины.

* Перейти в ветку lab.

* Развернуть с помощью vagrant обе машины. Одна ubuntu другая oracle linux. (vagrant up). Вход по сертификату.

* Определить какая машина является сервером, а какая клиентом. Сделать так что бы приложение на клиенте работало корректно после устранения всех проблем, В результате работы программы на клиенте будут формироваться логи. Необходимо удалять их каждые 7 дней.

* должна быть возможность показать результат теста и подключиться к нашей тестовой машине. Для возможности подключиться =компьютер, интернет, расшарить экран и подключиться терминалом по ssh

### Решение

1. В плейбуке 120.yml исправил таски с добавлением репозитория Docker и таски с установкой Docker'а.

```
#sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
 # - name: Add Docker repository key
 #   apt_key:
 #     id: "{{ apt_key_sig }}"
 #     keyserver: "{{ apt_key_url }}"
 #     state: present

#sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
 # - name: Add Docker repository and update apt cache
 #   apt_repository:
 #     repo: "{{ apt_repository }}"
 #     mode: '644'
 #     update_cache: yes
 #     state: present

 # - name: Install a docker package
 #   apt:
 #     name: "{{ docker_pkg_name }}"
 #     state: latest
 #     update_cache: yes
  
  - name: Add the GPG key for the official Docker repository
    shell: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    
  - name: Add the Docker repository to APT sources
    shell: add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
  - name: Update the package database with the Docker packages from the newly added repo
    shell: sudo apt-get update
    
  - name: Install Docker
    shell: apt-get install -y docker-ce
```

2. Сервером является machine120.test 192.168.56.120 (указано в job.sh), соответственно machine100.test 192.168.56.100 - клиент.


3. Для авторизации по сертификату через ssh с помощью puttygen генерируем приватный ключ в формат ppk, потом добавляем его в putty в разделе Connection > SSH > Auth.


4. На клиенте при запуске приложения `./job.sh` выдавалась ошибка `-bash: ./job.sh: /bin/sh^M: bad interpreter: No such file or directory`
В скрипте в конце каждой строки используется символ `^M`, это символ окончания строки, который используется в Windows-системах. Получается что при запуске скрипта путь до шелла выглядит как `/bin/sh^M` а такой директории не существует, поэтому выдается соответствующая ошибка.
Решенить данную проблему поможет утилита dos2unix с помощью команды `dos2unix job.sh` лишние символы удалятся из скрипта.


5. Порт приложения в докер-контейнере 8100, он пробрасывается на порт 8080 хостовой машины machine120.test это понятно из таска Docker is running. Принято решение пробросить данный порт на порт 8180, который указан на клиенте.
Выполнены команды:
```
vagrant@machine120:~$ sudo firewall-cmd --zone=public --add-masquerade --permanent
vagrant@machine120:~$ sudo firewall-cmd --zone=public --add-forward-port=port=8180:proto=tcp:toport=8080:toaddr=192.168.56.120 --permanent
vagrant@machine120:~$ sudo firewall-cmd --reload
```

6. При выполнении скрипта job.sh выдавалась ошибка `./job.sh: line 19: /usr/bin/python3: No such file or directory` которая решается установкой пакета `python3`


7. После выполненных манипуляций скрипт отрабатывает нормально:
```
vagrant@machine100 Job]$ sudo ./job.sh
11 November 2022|b9b353c943cb|14399|student devops hello devops student student|08:47:51|172.17.0.1|
```


8. Смотрим список заданий cron
```
[vagrant@machine100 cron.hourly]$ crontab -l
#Ansible: auto job
* * * * * /home/vagrant/Job/job.sh 2>>/home/vagrant/Job/job.err 1>>/home/vagrant/Job/job.log
```
Данная запись говорит о том, что скрипт `job.sh` будет выполняться каждую минуту. При успешном выполнении скрипта, результаты из файлового дескриптора стандартного вывода добавляются в /home/vagrant/Job/job.log. При выводе ошибки, результаты из файлового дескриптора вывода ошибок добавляются в /home/vagrant/Job/job.err


9. Чтобы задание из cron выполнялось без ошибок, необходимо дать права на каталог `/home/vagrant/Job/` пользователю vagrant 
```
vagrant@machine100 ~]$ sudo chown vagrant /home/vagrant/Job/
```


10. Добавляем в cron задание на удаление логов, на каждый 7-ой день месяца через `crontab -e` в результате получаем следующий список заданий:
```
[vagrant@machine100 Job]$ crontab -l
#Ansible: auto job
* * * * * /home/vagrant/Job/job.sh 2>>/home/vagrant/Job/job.err 1>>/home/vagrant/Job/job.log
0 0 */7 * * rm /home/vagrant/Job/job.err /home/vagrant/Job/job.log
```
