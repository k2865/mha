pkill mysqld
sleep 5
mkdir -p /data/57mysql/mysql3508/{data,logs,tmp}
ln -s /data/57mysql/mysql3508/ /3508
scp -P3322 db210:/3508/my3508.cnf /3508/
sed -i 's/210/211/g' /3508/my3508.cnf 
rm -rf /3508/data/* /3508/logs/*
chown -R mysql:mysql /data/57mysql/mysql3508
/usr/local/mysql57/bin/mysqld --defaults-file=/3508/my3508.cnf --initialize-insecure
/usr/local/mysql57/bin/mysqld --defaults-file=/3508/my3508.cnf&
sleep 2
/usr/local/mysql57/bin/mysql -S /tmp/mysql3508.sock -uroot  </tmp/create_t2_3508.sql
/usr/local/mysql57/bin/mysql -S /tmp/mysql3508.sock -uroot -pzstzst

