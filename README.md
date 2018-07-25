# docker-lnmp
Docker镜像，包括Linux + Nginx + Mysql + PHP + Redis

## 1. 功能
1. 支持PHP多版本切换(5.4/5.6/7.2)
2. Mysql映射到宿主机目录docker-lnmp/mysql
3. 支持mysql/nginx/php日志
4. 站点配置见docker-lnmp/conf/conf.d
5. 支持脚本定时备份mysql数据库、定时删除旧的备份

## 2. 使用说明
- 更新系统：yum -y upgrade
- 安装git(centos)
    ```
    $ yum -y install git
    ```
    - 禁止修改文件权限
        ```
        $ git config core.fileMode false
        $ git config --global core.fileMode false
        ```
- 安装docker(centos)
    ```
    $ yum install -y yum-utils \
      device-mapper-persistent-data \
      lvm2
    $ yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    $ yum -y install docker-ce
    $ docker --version
    $ service docker start
    ```
- 安装docker-compose
    ```
    $ cd /home/docker
    $ curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    $ chmod +x /usr/local/bin/docker-compose
    $ source ~/.bash_profile
    $ docker-compose --version
    ```
- 拉取docker-lnmp
    ```
    $ git clone git@github.com:echobar/docker-lnmp.git
    ```
- 配置docker-compose.yml
    如宿主机各端口（80, 3306, 6379, 9000）未被占用，请忽略本条。
    如宿主机有其它占用端口的服务，请务必修改宿主机与Docker容器的端口映射配置，如nginx的"80:80" 改为 "8000:80"，其它容器端口映射同理。
    如宿主机nginx端口修改后，宿主机上的Apache或Nginx可用反向代理将80端口回溯到映射前的端口如8000，再由Docker将8000映射到80，这样宿主机可不带端口访问，以Apache为例，在httpd-vhosts.conf里增加：
    ```
    <VirtualHost *:80>
    ServerName test.ledger.com
    
    ProxyVia Off
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://test.ledger.com:8000/
    ProxyPassReverse / http://test.com:8000/
    </VirtualHost>
    ```
    访问http://test.ledger.com即可
- 数据库
    - 数据库连接：数据库最好使用容器间连接，不要通过外网IP（否则访问数据库的速度会大打折扣），有两种方式，推荐第2种：
        - 内网IP方式
            查看各容器内网IP：
            ```
            $ docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
            ```
            内网IP可能因容器的重新up导致改变，所以容器停止重启后需检查IP是否改变
        - 直接使用标签
            host的值可直接使用docker-compose.yml里的数据库标签：mysql
    - Mysql8.0修改root密码
        root密码在docker-compose.yml里初始指定，如在创建容器后，可登录Mysql修改密码：ALTER user 'root'@'%' IDENTIFIED BY '123456'
    - Mysql修改时区
        默认时区会导致与北京时间相关8小时，在my.cnf的mysqld节增加：default-time-zone = '+8:00'
- 启动容器
    ```
    $ cd docker-lnmp
    $ docker-compose up
    ```
- 浏览器访问http://localhost
    站点目录 `docker-lnmp/www/site1`
- 定时备份数据库、删除旧备份数据库
    ```
    $ cat docker-lnmp/bk/bk_ledger_test.sh
        #!/bin/bash
        
        bk_dir=/home/docker/docker-lnmp/bk/db
        db_name=ledger_test
        time=` date +%Y%m%d%H `
        mysqldump -h 127.0.0.1 -P 9306 -u root -proot ${db_name} | gzip > $bk_dir/${db_name}_$time.sql.gz
        find $bk_dir -name "${db_name}_*.sql.gz" -type f -mtime +3 -exec rm {} \; > /dev/null 2>&1
    $ crontab -e
        30 3 * * * /home/docker/docker-lnmp/bk/bk_ledger_test.sh
    $ service crond reload
    ```
    本脚本定时（每天凌晨3:30执行备份并压缩备份文件，之后删除3天以前的备份文件），可根据需要修改脚本
- 切换PHP版本:
    ```
    $ docker-compose -f docker-compose54.yml up
    $ docker-compose -f docker-compose56.yml up
    ```
- License
MIT