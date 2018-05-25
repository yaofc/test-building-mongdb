# MongoDB Sharding 分散式儲存架構建置
## 一 . 前置工作
### 先建立 Replica Set 高可用性架構
## 二 . 建立 Config Server
### ***<font color="red">三台容器都要執行</font>***
```shell
mkdir -p /var/lib/mongodb-cfg
chown -R mongodb:mongodb /var/lib/mongodb-cfg
echo "storage:
  dbPath: /var/lib/mongodb-cfg
  journal:
    enabled: true
 
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod-cfgserv.log
 
sharding:
   clusterRole: configsvr
 
net:
  port: 27018
  bindIp: 0.0.0.0
 
processManagement:
  fork: true
  pidFilePath: /var/run/mongod-cfgserv.pid" >> /etc/mongod-cfgserv.conf

mongod -f /etc/mongod-cfgserv.conf --shutdown
echo "
security:
  keyFile: /var/lib/mongodb/mongodb-keyfile" >> /etc/mongod-cfgserv.conf

mongod -f /etc/mongod-cfgserv.conf
```
## 三 . 建立 Router
### 設置 db1 為 router
```shell
echo "systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod-router.log
 
sharding:
  configDB: 172.19.0.2:27018,172.19.0.3:27018,172.19.0.4:27018
  chunkSize: 64
 
net:
  port: 27017
  bindIp: 0.0.0.0
 
processManagement:
  fork: true
  pidFilePath: /var/run/mongodb-router.pid" >> /etc/mongod-router.conf

echo "
security:
  keyFile: /var/lib/mongodb/mongodb-keyfile" >> /etc/mongod-router.conf

mongos -f /etc/mongod-router.conf
```
#### 進入 db1 mongos 新增 user
```shell
mongo 172.19.0.2:27017
```
```mongodb
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

db.auth("admin", "admintest");
sh.addShard("rs-a/172.19.0.2:27019,172.19.0.3:27019,172.19.0.4:27019")
exit
```