搭建


####介绍
MHA（Master High Availability）,在传统MySQL复制框架下,是一个相对成熟的高可用解决方案，它由日本DeNA公司youshimaton（现就职于Facebook公司）开发，主要优势在于自动补全数据,并快速切换主节点。在MySQL故障切换过程中，MHA能做到在0~30秒之内自动完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA能在最大程度上保证数据的一致性。
####原理
MHA由两部分组成：MHA Manager（管理端）和MHA Node（数据节点）。MHA Manager可以单独部署在一台独立的机器上管理多个master-slave集群,也可以部署在一台slave节点上。MHA Node运行在每台MySQL服务器上，MHA Manager会定时探测集群中的master节点，当master出现故障时，它可以自动将最新数据的slave提升为新的master，然后将所有其他的slave重新指向新的master。整个故障转移过程对应用程序完全透明。
MHA原理总结为以下过程：
- 从宕机崩溃的master保存二进制日志事件（binlog events）;
- 识别含有最新更新的slave;
- 应用差异的中继日志(relay log) 到其他slave;
- 应用从master保存的二进制日志事件(binlog events);
- 提升一个slave为新master;
- 使用其他的slave连接新的master进行复制。

本次实验环境:
实验环境：(centos7.3 MySQL版本5.7.23)
功能|ip|名称|server_id|备注
---|:--:|---:
Monitor host|192.168.99.210|db210|1|也是一个slave
Master|192.168.99.211|db211|2|vip:192.168.99.253
Candicate master |192.168.99.212|db212|3|

####安装
- 配置所有节点两两SSH互信
 在一个节点上生成authorized_keys、id_rsa、id_rsa.pub三个文件,并将这个文件复制到所有节点中.即可实现SSH互信.
```
#ssh-keygen -t rsa 
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
5d:9d:9e:b1:fa:23:48:57:80:cb:dc:8f:24:b6:b2:6f root@db215
The key's randomart image is:
+--[ RSA 2048]----+
|           .     |
|          . .. . |
|         o o..+  |
|         .*.o..+ |
|        S..+ ++  |
|        . o o..  |
|         + o.    |
|        . E ...  |
|         o.  ... |
+-----------------+
#cd ~/.ssh/
[root@db215_12:05:13 /root/.ssh]  
#ll
total 8
-rw------- 1 root root 1679 Aug  6 12:04 id_rsa
-rw-r--r-- 1 root root  392 Aug  6 12:04 id_rsa.pub
#cat id_rsa.pub >authorized_keys
#ll
total 12
-rw-r--r-- 1 root root  392 Aug  6 12:09 authorized_keys
-rw------- 1 root root 1679 Aug  6 12:04 id_rsa
-rw-r--r-- 1 root root  392 Aug  6 12:04 id_rsa.pub
[root@db215_12:09:07 /root/.ssh]  
#cat authorized_keys 
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoHQ/bU5pGVBkSk76wxdJ37U0l9O0DF5pCwJlvbFAr96pfBLu30/1hZ+tX/yrLF//Y68qC2fV2og4I5o25e5c9HYbiTiaC4mqO42ij3rBe96H1FUGG5/3sYvuTmPXXI2Sh+mlqM/1omnl0wjTVc0QXZhDTEqfB2p6AWjvCq5xkPKxB+smtEHlJiymKnQhd+jffpsrW50KLbbCr+mKb3DXyquuHDYEze2WrK6+RHEZtOyOedrTqV5yzv3rj/4ecehTzdEE8XPvvnu0cALQExHtNVQ3II9x3FprYTBFL9/klG9f8FfABLv6EhLIg67nZnpFC2f0ihgQf8KJsT8KIf9HD root@db215

``` 


- 软件下载及安装指南
https://github.com/yoshinorim/mha4mysql-manager/releases
https://github.com/yoshinorim/mha4mysql-manager/wiki/Installation#installing-mha-node
- 安装依赖包(所有节点上安装)
``` 
yum install -y perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager perl-Time-HiRes
```
- 安装节点(所有节点上安装)
```bash
-[root@db210_10:30:14 /opt/MHA]  
#rpm -ivh mha4mysql-node-0.58-0.el7.centos.noarch.rpm 
Preparing...                          ################################# [100%]
	package mha4mysql-node-0.58-0.el7.centos.noarch is already installed
```
- 安装manager(只需要在一个节点上安装)

```bash
[root@db210_10:32:09 /opt/MHA]  
#rpm -ivh mha4mysql-manager-0.58-0.el7.centos.noarch.rpm 
Preparing...                          ################################# [100%]
Updating / installing...
   1:mha4mysql-manager-0.58-0.el7.cent################################# [100%]
[root@db210_10:33:11 /opt/MHA]  
#masterha_
masterha_check_repl       masterha_check_status     masterha_manager          masterha_master_switch    masterha_stop             
masterha_check_ssh        masterha_conf_host        masterha_master_monitor   masterha_secondary_check  

```

- manager的配置
需要配置/etc/masterha下6个文件(如果没有则创建), masterha_default.cnf app1.conf 
- masterha_default.cnf
```
[server default]
#log_level=debug
#MySQL的用户和密码
user=wyz
password=xxxxx
#系统ssh用户
ssh_user=root
ssh_port=3322
#复制用户
repl_user=rpl
repl_password=xxxx
#监控
ping_interval=3
#shutdown_script=""
#切换调用的脚本
master_ip_failover_script= /etc/masterha/master_ip_failover
master_ip_online_change_script= /etc/masterha/master_ip_online_change
```
- app1.conf
```
[server default]
#mha manager工作目录
manager_workdir = /var/log/masterha/app1
manager_log = /var/log/masterha/app1/app1.log
remote_workdir = /var/log/masterha/app1
[server1]
hostname=192.168.99.210
port=3307
master_binlog_dir = /data/57mysql/mysql3508/logs
candidate_master = 0
check_repl_delay = 0     #用防止master故障时，切换时slave有延迟，卡在那里切不过来。
[server2]
hostname=192.168.99.211
port=3307
master_binlog_dir=/data/57mysql/mysql3508/logs
candidate_master=1
check_repl_delay=0
[server3]
port=3307
hostname=192.168.99.212
master_binlog_dir=/data/57mysql/mysql3508/logs
candidate_master=1
check_repl_delay=0
```
- init_vip.sh
```
vip="192.168.99.253/24"
/sbin/ip addr add $vip dev ens192
\\ens192为网卡名字,192.168.99.253为vip地址.
```
- drop_vip.sh
```
vip="192.168.99.253"
/sbin/ip addr del $vip dev ens192
```
- master_ip_failover
```
//此文件内容太多,主要修改以下位置.如果需要全文件可邮件k2865#qq.com
#自定义该组机器的vip
my $vip = "192.168.99.253";
my $if = "ens192";
#定义网关
my $gw = "192.168.99.254";
```
- master_ip_online_change
```
//此文件内容太多,主要修改以下位置.如果需要全文件可邮件k2865#qq.com
my $_tstart;
my $_running_interval = 0.1;
#添加vip定义
my $vip = "192.168.99.253";
my $if = "ens192";
```
- **将以上6个文件复制到所有节点相同位置(/etc/masterha/)**

#### 构建1主2从的主从复制结构
为了提高测试速度,临时整理了脚本如下(未考虑mysql依赖包),仅供参考.:
- master
init_3508.sh
create_t2_3508.sql
```sql
alter user user() identified by 'zstzst';
grant all on *.* to 'wyz'@'%' identified by 'wyzwyz';
grant replication slave on *.* to 'repl'@'%' identified by 'repl4slave';
create database sysbench_testdata;
CREATE DATABASE wenyz;
use wenyz;
CREATE TABLE `t2` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ti` varchar(100) NOT NULL,
  `date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4079859 DEFAULT CHARSET=utf8;

delimiter $
create procedure em(IN acc int(20))
BEGIN
DECLARE i INT(11);
SET i = 0;
loop1: WHILE i<acc DO
insert into t2(ti,date) values(substring(MD5(RAND()),floor(RAND()*26)+1,15),now()) ;
SET i=i+1;
END WHILE loop1;
end $
delimiter ;
call em(365);

```
检查集群状态
- manager上执行

masterha_check_repl --global_conf=/etc/masterha/masterha_default.conf --conf=/etc/masterha/app1.conf
masterha_manager  --global_conf=/etc/masterha/masterha_default.conf --conf=/etc/masterha/app1.conf
