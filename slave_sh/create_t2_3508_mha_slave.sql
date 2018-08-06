set sql_log_bin=0;
alter user user() identified by 'zstzst';
grant all on *.* to 'wyz'@'%' identified by 'wyzwyz';
set sql_log_bin=1;
change master to master_host='db210',master_port=3508,master_user='repl',master_password='repl4slave',master_auto_position=1;
start slave;
show slave status\G;
