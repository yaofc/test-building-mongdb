# MongoDB Replica Set 高可用性架構
## 一 . 前置工作
### 安裝 docker & docker-compsoe
```shell
bash install.sh
```
### 建立 docker 容器
```shell
docker-compose up -d
```
docker-compose.yml (建立三台ubuntu 16.04機器 ,並設置ip)
```dockerfile
version: '2'
services:
  db1:
    image: ubuntu:16.04
    networks:
      vpcbr:
        ipv4_address: 172.19.0.2
    tty: true
  db2:
    image: ubuntu:16.04
    networks:
      vpcbr:
        ipv4_address: 172.19.0.3
    tty: true
  db3:
    image: ubuntu:16.04
    networks:
      vpcbr:
        ipv4_address: 172.19.0.4
    tty: true
networks:
  vpcbr:
    driver: bridge
    ipam:
      config:
      - subnet: 172.19.0.0/24
```
## 二 . 建置 MongoDB
### ***<font color="red">三台容器都要執行</font>***
### 進入 docker 容器
```shell
docker-compose exec 容器名稱 bash
```
### 安裝 MongoDB 3.2
```shell
apt-get update && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list && apt-get update && apt-get install -y mongodb-org
```
### 安裝 vim openssl (docker ubuntu image 預設沒裝)
```shell
apt-get install -y openssl vim
```
### 設定 mongod.conf (mongod 服務在 port 27019)
```shell
sed -i '/bindIp: 127.0.0.1/c \ \ bindIp: 0.0.0.0' /etc/mongod.conf
sed -i '/port: 27017/c \ \ port: 27019' /etc/mongod.conf
```
### 開啟 mongod 服務
```shell
mongod --config /etc/mongod.conf --fork
```
### 進入mongod 新增user
```shell
mongo ip:27019
```
```mongo
use admin

db.createUser( {
    user: "yaofc",
    pwd: "yaofctest",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  });

db.createUser( {
    user: "admin",
    pwd: "admintest",
    roles: [ { role: "root", db: "admin" } ]
  });

exit
```
## 三 . 設定 PRIMARY & SECONDARY節點
### 設置 db1 為 PRIMARY ,db2 & db3 為 SECONDARY
#### 進入 db1 產生金鑰
```shell
openssl rand -base64 741 > /var/lib/mongodb/mongodb-keyfile
chmod 600 /var/lib/mongodb/mongodb-keyfile
chown mongodb.mongodb /var/lib/mongodb/mongodb-keyfile
vi /var/lib/mongodb/mongodb-keyfile
```
#### 進入 db2 & db3 貼上 db1 的金鑰
```shell
vi /var/lib/mongodb/mongodb-keyfile
chmod 600 /var/lib/mongodb/mongodb-keyfile
chown mongodb.mongodb /var/lib/mongodb/mongodb-keyfile
```
#### 三台容器更改 mongod.conf(設定 replSetName & 金鑰)
```shell
sed -i '/security:/a security:\n\ \ keyFile: /var/lib/mongodb/mongodb-keyfile' /etc/mongod.conf
sed -i '/replication:/a replication:\n\ \ replSetName: rs-a' /etc/mongod.conf
pkill mongod
mongod --config /etc/mongod.conf --fork
```
#### 進入 db1 mongod 設定 Replica Set
```shell
mongo 172.19.0.2:27019
```
```mongodb
use admin
db.auth("admin", "admintest");
rs.initiate()
rs.conf()

rs.add("172.19.0.3:27019")
rs.add("172.19.0.4:27019")
cfg = rs.conf()
cfg.members[0].host = "172.19.0.2:27019"
rs.reconfig(cfg)
rs.status()
exit
```
