create table users (id integer primary key, name varchar(255));
create table tweets (id integer primary key, content varchar(255), in_reply integer references tweets(id));
