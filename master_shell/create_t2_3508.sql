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
create procedure employee(IN acc int(20))
BEGIN
DECLARE i INT(11);
SET i = 0;
loop1: WHILE i<acc DO
insert into t2(ti,date) values(substring(MD5(RAND()),floor(RAND()*26)+1,15),now()) ;
SET i=i+1;
END WHILE loop1;
end $
delimiter ;
call employee(365);
use wenyz;
select count(*) from t2;
checksum table t2;
