-- 连接到数据库
-- mysql -h 127.0.0.1 -P 3307 -uroot -proot -A

-- 新建数据库及数据表
create schema demo_ds_0;
create table if not exists demo_ds_0.t_order_0 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_1 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_2 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_3 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_4 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_5 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_6 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_7 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_8 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_9 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_10 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_11 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_12 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_13 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_14 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_0.t_order_15 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));

create schema demo_ds_1;
create table if not exists demo_ds_1.t_order_0 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_1 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_2 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_3 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_4 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_5 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_6 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_7 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_8 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_9 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_10 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_11 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_12 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_13 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_14 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));
create table if not exists demo_ds_1.t_order_15 (order_id bigint not null auto_increment, user_id int not null, status varchar(50), primary key (order_id));

-- 使用数据库
show schemas;
use sharding_db;
insert into t_order(user_id, status) values(1, "OK"),(1, "FAIL");
insert into t_order(user_id, status) values(2, "OK"),(2, "FAIL");

-- 通过查询虚拟表 t_order
 select * from t_order;