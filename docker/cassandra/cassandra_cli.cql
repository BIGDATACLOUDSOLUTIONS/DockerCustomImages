/*

Start the VM and Download the cassandra from https://cassandra.apache.org/doc/latest/cassandra/getting_started/installing.html

cd /etc/cassandra
vi cassandra.yml

search for materialized_views_enabled and change the value of materialized_views_enabled from false to true

sudo service cassandra start
sudo service cassandra status
sudo service cassandra stop

nodetool status
*/

CREATE KEYSPACE test_keyspace WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'} AND durable_writes = 'true';
DESCRIBE KEYSPACES;
DROP KEYSPACE test_keyspace;
USE test_keyspace;


CREATE TABLE employee_by_id (id int PRIMARY KEY,name TEXT, position TEXT);
DESCRIBE TABLES;
DROP TABLE employee_by_id;

CREATE TABLE employee_by_car_make(car_make text, id int, car_model text, PRIMARY KEY(car_make, id));
DESCRIBE TABLE employee_by_car_make;

CREATE TABLE employee_by_car_make_sorted(car_make TEXT, age INT, id INT, name TEXT, PRIMARY KEY(car_make, age, id));

CREATE TABLE employee_by_car_make_and_model(car_make TEXT, car_model TEXT, id INT, name TEXT, PRIMARY KEY((car_make,car_model), id));


CONSISTENCY;
CONSISTENCY QUORUM;
CONSISTENCY ONE;


/* INSERT Data */
--------------------------------------------------------------------------------------------------------
INSERT INTO employee_by_id(id,name,position) VALUES(1, 'John','Manager');
INSERT INTO employee_by_id(id,name,position) VALUES(2, 'Bob','CEO');

SELECT * from employee_by_id;


SELECT * from employee_by_id where id=1;  --> This will work as clustering column in tabke is ID. This means data of a given id will be available on a single node.
SELECT * from employee_by_id where name='Bob';  --> This will fail  as clustering column in tabke is only ID. That means for name, the data will scattered over various nodes.

--------------------------------------------------------------------------------------------------------
DESCRIBE TABLE employee_by_car_make;
INSERT INTO employee_by_car_make(car_make, id, car_model) VALUES('BMW', 1, 'Sports Car');
INSERT INTO employee_by_car_make(car_make, id, car_model) VALUES('BMW', 2, 'Sports Car');
INSERT INTO employee_by_car_make(car_make, id, car_model) VALUES('AUDI', 4, 'Truck');
INSERT INTO employee_by_car_make(car_make, id, car_model) VALUES('AUDI', 5, 'Hatch Back');

SELECT * from employee_by_car_make where car_make='BMW';
SELECT * from employee_by_car_make where car_make='AUDI';
SELECT * from employee_by_car_make where id=1;  --> This will fail  as clustering column in tabke is only car_make. That means for id, the data will scattered over various nodes.

SELECT * from employee_by_car_make where car_make='BMW' ORDER BY id;

--------------------------------------------------------------------------------------------------------
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('BMW','Hatch Back',1,'John');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('BMW','Hatch Back',1,'Bob');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id) VALUES ('BMW','Hatch Back',2);
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id) VALUES ('AUDI','Hatch Back',3);
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('BMW','TRUCK',8,'FRANK');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('ADUI','TRUCK',7,'AMY');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('ADUI','SPORTS CAR',4,'TIM');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('ADUI','SPORTS CAR',5,'JIM');
INSERT INTO employee_by_car_make_and_model(car_make,car_model,id,name) VALUES ('ADUI','SPORTS CAR',6,'NICK');


SELECT * FROM employee_by_car_make_and_model;
SELECT * FROM employee_by_car_make_and_model WHERE car_make='BMW'; --> This will fail as table is partitioned on 2 keys car_make and car_model

SELECT * FROM employee_by_car_make_and_model WHERE car_make='BMW' and car_model='Hatch Back'; 

--------------------------------------------------------------------------------------------------------
SELECT CAR_MAKE, CAR_MODEL, WRITETIME(car_model) from employee_by_car_make;

UPDATE employee_by_car_make SET car_model='TRUCK' WHERE car_make= 'BMW' and ID=1;

UPDATE employee_by_car_make USING TTL 60 SET car_model='TRUCK' WHERE car_make= 'BMW' and ID=2;  --> This will set TIME TO LIVE FOR car_model. The updated value will only live for 60 secods and then will expire and become null;
select * from employee_by_car_make;

--------------------------------------------------------------------------------------------------------
ALTER TABLE employee_by_id ADD phone set<TEXT>;

SELECT * FROM employee_by_id;
UPDATE employee_by_id SET phone = {'343', '565'} WHERE id=1;

-- TO add more element to same set
UPDATE employee_by_id SET phone = phone + {'555'} WHERE id=1;

-- TO remove more element from same set
UPDATE employee_by_id SET phone = phone - {'555'} WHERE id=1;

-- TO remove all elements from same set
UPDATE employee_by_id SET phone = {} WHERE id=1;
--------------------------------------------------------------------------------------------------------
--Secondary indexes
select * from employee_by_id where name='John';  --> This will fail as name is not the partition column. To make it work add ALLOW FILTERING;
select * from employee_by_id where name='John' ALLOW FILTERING; -- NOT RECOMMENDED

CREATE INDEX ON employee_by_id(name); -- NOT RECOMMENDED
select * from employee_by_id where name='John';  --> When we create index, we don't need to provide ALLOW FILTERING;


--------------------------------------------------------------------------------------------------------
--uuid()

CREATE TABLE employee_by_uuid(id uuid PRIMARY KEY, first_name TEXT, last_name TEXT);
INSERT INTO employee_by_uuid(id,first_name,last_name) VALUES(uuid(),'tom','dunne');
INSERT INTO employee_by_uuid(id,first_name,last_name) VALUES(uuid(),'tim','smith');
INSERT INTO employee_by_uuid(id,first_name,last_name) VALUES(uuid(),'bob','hanson');
SELECT * FROM employee_by_uuid;

--------------------------------------------------------------------------------------------------------
--timeuuid
CREATE TABLE employee_by_timeuuid(id timeuuid PRIMARY KEY, first_name TEXT, last_name TEXT);
INSERT INTO employee_by_timeuuid(id,first_name,last_name) VALUES(now(),'tom','jones');
INSERT INTO employee_by_timeuuid(id,first_name,last_name) VALUES(now(),'ally','smith');
INSERT INTO employee_by_timeuuid(id,first_name,last_name) VALUES(now(),'kate','smith');
SELECT * FROM employee_by_timeuuid;

--------------------------------------------------------------------------------------------------------
--COUNTER
CREATE TABLE purchases_by_customer_id(id uuid PRIMARY KEY, purchases counter);
UPDATE purchases_by_customer_id SET purchases=purchases+1 WHERE id=uuid(); --> This will insert a new records with new id
UPDATE purchases_by_customer_id SET purchases=purchases+1 WHERE id=uuid(); --> This will insert a new records with new id
UPDATE purchases_by_customer_id SET purchases=purchases+1 WHERE id=uuid(); --> This will insert a new records with new id

SELECT * FROM purchases_by_customer_id;
UPDATE purchases_by_customer_id SET purchases=purchases+1 WHERE id=3fba0d87-c3da-4032-b164-ec338f30049a; --> This will increase the counter for existing uuid  
-- Note if column type is uuid, don't put the values in quotes in where condition
SELECT * FROM purchases_by_customer_id;

UPDATE purchases_by_customer_id SET purchases=purchases - 1 WHERE id=3fba0d87-c3da-4032-b164-ec338f30049a; 
SELECT * FROM purchases_by_customer_id;

--------------------------------------------------------------------------------------------------------
-- Importing and Exporting Data
/*
car_make,car_model,start_year,id,first_name,last_name,department
BMW,Saloon,2011,1,Johny,Deep,IT
AUDI,Saloon,2013,2,Meryl,Streep,HR
LEXUS,Sports,2011,3,Brad,Pitt,IT
AUDI,Sports,2012,4,Tom,Hanks,FI
BMW,Compact,2012,5,Angelina,Jolie,FI
BMW,Saloon,2011,6,Tom,Cruise,HR
AUDI,Compact,2013,7,Scarlett,Johansson,IT
LEXUS,Compact,2013,8,Matt,Damon,IT
NISSAN,Saloon,2013,9,Julia,Roberts,FI
BMW,Saloon,2011,10,Nicole,Kidman,HR
NISSAN,Compact,2012,11,George,Clooney,HR
AUDI,Saloon,2012,12,Dwayne,Johnson,IT
AUDI,Sports,2011,13,Natalie,Portman,FI


vi car_make_cassandra.csv
*/


CREATE TABLE test_csv_import(car_make TEXT,car_model TEXT,start_year int, id int, first_name TEXT, last_name TEXT, department text, PRIMARY KEY(car_make,car_model,start_year,id));

-- Import
COPY test_csv_import (car_make,car_model,start_year, id, first_name, last_name, department) FROM '/home/ubuntu/cassandra/car_make_cassandra.csv' WITH DELIMITER=',' AND HEADER=TRUE;
SELECT * FROM test_csv_import;


-- Export
COPY test_csv_import TO '/home/ubuntu/cassandra/car_make_cassandra_export.csv' WITH DELIMITER=',' AND HEADER=TRUE;
COPY test_csv_import(car_make,car_model,id,department,first_name,last_name,start_year) TO '/home/ubuntu/cassandra/car_make_cassandra_export_2.csv' WITH DELIMITER=',' AND HEADER=TRUE;

--------------------------------------------------------------------------------------------------------
-- MATERIALIZED view
CREATE TABLE test_keyspace.employee_by_car_make(car_make TEXT,car_model TEXT, id int, department text,first_name TEXT, last_name TEXT, start_year int,  PRIMARY KEY(car_make,car_model,id));
COPY test_keyspace.employee_by_car_make (car_make,car_model,id,department,first_name,last_name,start_year) FROM  '/home/ubuntu/cassandra/car_make_cassandra_export_2.csv' WITH DELIMITER=',' AND HEADER=TRUE;

SELECT * FROM test_keyspace.employee_by_car_make;


CREATE MATERIALIZED VIEW test_keyspace.employee_by_department
AS SELECT * 
FROM test_keyspace.employee_by_car_make 
WHERE department IS NOT NULL AND
car_make IS NOT NULL AND 
car_model IS NOT NULL AND 
id IS NOT NULL
PRIMARY KEY(department,car_make,car_model,id);


SELECT * FROM test_keyspace.employee_by_department WHERE department='HR';

UPDATE test_keyspace.employee_by_car_make SET department='IT' WHERE car_make='AUDI' AND car_model='Saloon' and id=2;
SELECT * FROM test_keyspace.employee_by_department WHERE department='IT' and car_make='AUDI' AND car_model='Saloon' and id=2;



DROP MATERIALIZED VIEW test_keyspace.employee_by_department;
--------------------------------------------------------------------------------------------------------




