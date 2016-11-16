 -- Task 1

create database if not exists list3;

use list3;

create table if not exists sale(Goods varchar(30), Month varchar(30), Value int (10));


insert into sale(Goods, Month, Value) values ("Shoes", "January", 230),("Shoes", "January", 100), ("Shirt", "January", 50), ("Shirt", "February", 80), ("Tie", "March", 190);

-- Bad, not dynamic
  delimiter $$
  create procedure foo1()
  begin
  declare x varchar(30);
	select Goods, sum(if(Month = "January", Value, null )) as January,
  sum(if(Month = "February", Value, null )) as February,
  sum(if(Month = "March", Value, null )) as March
  from sale
  group by Goods;

  end $$
  delimiter ;

-- OK dynamic
delimiter $$
create procedure foo2()
begin
SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      'SUM(IF(Month = ''',
      Month,
      ''', Value, NULL)) AS ',
      Month
    )
  ) INTO @sql
FROM sale;
SET @sql = CONCAT('SELECT Goods, ', @sql, ' FROM sale GROUP BY Goods');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
end $$
delimiter ;


-- Task II

create table if not exists club(Name varchar(30), Adress varchar(30));

create table if not exists team(Name varchar(30), MembersQuantity int(5));

create table if not exists concert(ClubName varchar(30), ClubAdress varchar(30), TeamName varchar(30), TeamMembersQuantity varchar(30), Date datetime);



-- http://www.mysqltutorial.org/mysql-error-handling-in-stored-procedures/
