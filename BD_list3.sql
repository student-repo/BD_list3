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
create procedure foo2(
  in func varchar(30))
begin
SET @sql = NULL;
SELECT
  GROUP_CONCAT(DISTINCT
    CONCAT(
      func,'(IF(Month = ''',
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


-- Task II A

create table if not exists club(Name varchar(30), Address varchar(30));

create table if not exists team(Name varchar(30), MembersQuantity int(5));

-- unique columne
-- create table if not exists concerts(ClubName varchar(30), ClubAddress varchar(30), TeamName varchar(30), TeamMembersQuantity varchar(30), Date datetime, unique(ClubName, ClubAddress, TeamName, TeamMembersQuantity, Date));

create table if not exists concerts(ClubName varchar(30), ClubAddress varchar(30), TeamName varchar(30), TeamMembersQuantity int(5), Date datetime);

create table if not exists concert(ClubName varchar(30), TeamName varchar(30), Date datetime);
-- without null values
-- insert into team(Name, MembersQuantity) values ("TeamName1", 1), ("TeamName2", 2), ("TeamName3", 3), ("TeamName4", 4), ("TeamName5", 5);
-- with null values
insert into team(Name, MembersQuantity) values ("TeamName1", null), ("TeamName2", 2), ("TeamName3", 3), ("TeamName4", 4), ("TeamName5", null);
-- without null values
-- insert into club(Name, Address) values ("ClubName1", "Address1"), ("ClubName2", "Address2"), ("ClubName3", "Address3");
-- with null values
insert into club(Name, Address) values (null, "Address1"), ("ClubName2", null), ("ClubName3", "Address3");
-- without null values
-- insert into concert(ClubName, TeamName, Date) values ("ClubName1", "TeamName2", date("2014-11-11")), ("ClubName3", "TeamName2", date("2015-11-11")), ("ClubName2", "TeamName5", date("2014-10-21")), ("ClubName3", "TeamName1", date("2014-02-15")), ("ClubName1", "TeamName2", date("2015-05-01")), ("ClubName2", "TeamName3", date("2015-03-11"));
-- with null values
insert into concert(ClubName, TeamName, Date) values ("ClubName1", "TeamName2", date("2014-11-11")), ("ClubName3", "TeamName2", date("2015-11-11")), ("ClubName2", "TeamName5", date("2014-10-21")), ("ClubName3", "TeamName1", date("2014-02-15")), ("ClubName1", "TeamName2", date("2015-05-01")), ("ClubName2", "TeamName3", date("2015-03-11"));

insert into concerts (ClubName, ClubAddress, TeamName, TeamMembersQuantity, Date) select club.Name, club.Address, team.Name, MembersQuantity, Date from concert inner join club on concert.ClubName=club.Name inner join team on concert.TeamName=team.Name;

    -- insert into concerts(ClubName, ClubAddress, TeamName, TeamMembersQuantity, Date) values ("ClubName2", "Address2", "TeamName3", 3, date("2015-03-11"));


    DELIMITER $$

  CREATE TRIGGER insert_concerts_controler
     BEFORE INSERT ON concerts FOR EACH ROW
     BEGIN
    --  make table club complete
     IF new.ClubName is not null
     and new.ClubAddress is not null
     and (SELECT COUNT(*) FROM club
          WHERE Name=new.ClubName
          and Address is null) > 0
     THEN
          update club set Address=new.ClubAddress where Name=new.ClubName;
     elseif new.ClubName is not null
     and new.ClubAddress is not null
     and (SELECT COUNT(*) FROM club
          WHERE Address=new.ClubAddress
          and Name is null) > 0 then
          update club set Name=new.ClubName where Address=new.ClubAddress;
     END IF;
  -- make table team complete
     IF new.TeamName is not null
     and new.TeamMembersQuantity is not null
     and (SELECT COUNT(*) FROM team
          WHERE Name=new.TeamName
          and MembersQuantity is null) > 0
     THEN
          update team set MembersQuantity=new.TeamMembersQuantity where Name=new.TeamName;
     END IF;

  -- trow and handle errors
          IF (SELECT COUNT(*) FROM concerts
               WHERE ClubName=new.ClubName
               and ClubAddress=new.ClubAddress
               and TeamName=new.TeamName
              and TeamMembersQuantity=new.TeamMembersQuantity
              and Date=new.Date) > 0
          THEN
               SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Cannot add row, tuple exists in table concerts';
          elseif (select count(*) from club
            where Name=new.ClubName
            and Address=new.ClubAddress) < 1
            or (select count(*) from team
            where Name=new.TeamName
            and MembersQuantity=new.TeamMembersQuantity) < 1 then
            SIGNAL SQLSTATE '45000'
                 SET MESSAGE_TEXT = 'Cannot add row, such club or team doesnt exists';
                --  complete table concert
            else
            insert into concert(ClubName, TeamName, Date) values (new.ClubName, new.TeamName, new.Date);
          END IF;
     END $$
  delimiter ;


-- Task II B

DELIMITER $$

CREATE TRIGGER update_concerts
 after update ON concerts FOR EACH ROW
 BEGIN

update club set Name=new.ClubName, Address=new.ClubAddress where Name=old.ClubName and Address=old.ClubAddress;
update team set Name=new.TeamName, MembersQuantity=new.TeamMembersQuantity where Name=old.TeamName and MembersQuantity=old.TeamMembersQuantity;
update concert set ClubName=new.ClubName, TeamName=new.TeamName, Date=new.Date where ClubName=old.ClubName and TeamName=old.TeamName and Date=old.Date;

 END $$
delimiter ;


DELIMITER $$

CREATE TRIGGER delete_concerts
 after delete ON concerts FOR EACH ROW
 BEGIN

delete from concert where ClubName=old.ClubName and TeamName=old.TeamName and Date=old.Date;

  IF (SELECT COUNT(*) FROM concert
       WHERE ClubName=old.ClubName
       and TeamName=old.TeamName
      and Date=old.Date) <= 0
  THEN
delete from club where Name=old.ClubName;
delete from team where Name=old.TeamName;
  end if;
 END $$
delimiter ;


-- http://www.mysqltutorial.org/mysql-error-handling-in-stored-procedures/

-- http://dev.mysql.com/doc/refman/5.7/en/declare-handler.html

-- http://dev.mysql.com/doc/refman/5.7/en/error-messages-server.html

-- https://dev.mysql.com/doc/refman/5.5/en/signal.html#signal-effects



-- Task 3

-- http://webcheatsheet.com/sql/mysql_backup_restore.php

--
-- Czesc I (Backup and Restoring)
--
-- Backup czyli tworzenie kopii zapasowych to jeden ze skutecznych sposobow na zabezpieczenie przed utrata danych.
-- Pracujac na bazach danych niezmiernie latwo jest popelnic jakis blad ktory skutecznie uszkodzi lub wyczysci
-- nasza baze ktora czesto zawiera cenne informacje. W zwiazku z tym warto co jakis czas zrobic tak zwany backup
-- ktory zapusuje stan naszej bazy danych i jesli cos zepsujemy to bardzo latwo przywrocic poprzedni stan.
-- MySql zapewnia szereg przydatnych funkcjonalnosci wspierajacych szybkie tworzenie kopii zapasowych.
-- Wykorzystuje sie do tego komende $mysqldump -u nazwa_uzytkownika_bazy_dancyh -p nazwa_bazy_danych >
-- sciezka_i_nazwa_pliku_w_ktorym_bedzie_zapisany_backup (w moim przypadku pelna komenda bedzie miala posatac
-- np.  $mysqldump -u root -p northwind > ~/Deskop/northwind_backup.sql ). Mysql zapewnia rowniez szereg
-- przydanych rozszerzen takich jak: robienie backupa kilku baz danych na raz do jednego pliku (wystarczy po
-- -p dopisac --databases nazwa_bazy_danych_1 nazwa_bazydanych_2 itd.) lub stworzenie kopii wszystkich baz danych
-- (po -p dopisujemy --all-databases). Jesli dzialamy na duzych bazach dabych bardzo przydatna funkcjonalnoscia
-- jest robienie kopii zapasowych od razu skompresowanych, mozna to zrobic za pomoca potoku $mysqldump -u
-- nazwa_uzytkownika_bazy_dancyh -p  nazwa_bazy_danych | gzip -9 > sciezka_i_nazwa_pliku. Inne rozszerzenia
-- to np. -add-drop-table ktory wymusza przed stworzeniem tablicy usuniecie jej jesli tablica o takiej nazwie
-- instnieje oraz --no-data krorego backup przywraca jedynie struktury tablic pomijajac ich zawartosc. Pliki
-- w ktorych zapisalismy backup to zwykle pliki z rozszerzeniem .sql ktre zawieraja komendy aby stworzyc na nowo
-- nasza baze danych.
-- (gunzip < backupfile.sql.gz | mysql -u root -p northwind
--   mysqldump -u root -p northwind | gzip -9 > backupfile.sql.gz
--    mysql -u root -p foo < backupfile.sql
--    mysqldump -u root -p --all-databases > alldb_backup.sql
-- )
--
--
-- Restoring czyli przywrocenie stanu bazy danych za pomoca kopii zapasowej. Jest to bardzo prosta i intuicyjna
-- czynnosc. Pomocna jest tu komenda $ mysql -u nazwa_uzytkownika_bazy_dancyh -p nazwa_bazy_do_ktorej_chcemy_przywrocic_dane
--  < nazwa_pliku_w_ktorym_znajduje_sie_backup (pelna komenda np.  $ mysql -u root -p northwind < backupfile.sql ). Aby
--  przywrocic backup z zapakowanego pliku mozna to zrobic bez koniecznosci jego rozpakowywania komenda $ gunzip < nazwa_zapakowanej_kopii_zapasowej.sql.gz
--   | mysql -u nazwa_uzytkownika_bazy_dancyh -p nazwa_bazy_danych_do_ktorej_zostania_przywrocone_dane. Przywrocic dane z
--   kopi zapasowej mozna rowniez z poziomu MySqla, deklarujac uzywanie bazy danych w ktorej chcemy zapisac backup
--   oraz wykoanie komendy mysql> source sciezka_do_pliku_z_kopia_zapasowa.sql
--
--
--
-- Czesc II (Replication)
--
-- Replication w kontekscie MySqla oznacza proces ktory pozwala na latwe utrzymywanie kopii bazy danych ktore sa
-- automatycznie kopiowane z servera master do jednego lub wielu serverow slave (niewolnik). Wszystkie aktualizacje
-- na serverze master sa natychmiastowo replikowane do servera slave. Koncepcja replication nie uchroni nas przed
-- wieloma zagrozeniami utraty bazy danych takich jak np przypadkowe usuniecie bazy poniewaz jesli usuniemy baze na
-- masterze to automatycznie ta baza zostanie usunieta na serverze slave. Replication chroni nas jednak skutecznie
-- przed awariami sprzetu komputerowego.
--



-- docker pull percona
--
--
-- sudo mkdir -p /opt/Docker/masterdb/data /opt/Docker/slavedb/data
--
--
-- sudo mkdir -p /opt/Docker/masterdb/cnf /opt/Docker/slavedb/cnf
--
--
-- sudo vi /opt/Docker/masterdb/cnf/config-file.cnf
-- # Config Settings:
-- [mysqld]
-- server-id=1
-- binlog_format=ROW
-- log-bin
--
--
-- sudo vi /opt/Docker/slavedb/cnf/config-file.cnf
-- # Config Settings:
-- [mysqld]
-- server-id=2
--
--
-- sudo docker run --name masterdb -v /opt/Docker/masterdb/cnf:/etc/mysql/conf.d -v /opt/Docker/masterdb/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mysecretpass -d percona:5.6
--
--
-- sudo docker exec -ti masterdb 'mysql' -uroot -pmysecretpass -vvv -e"GRANT REPLICATION SLAVE ON *.* TO repl@'%' IDENTIFIED BY 'slavepass'"
--
--
-- sudo docker exec -ti masterdb 'mysql' -uroot -pmysecretpass -e"SHOW MASTER STATUS"
--
--
-- sudo docker run --name slavedb -d -v /opt/Docker/slavedb/cnf:/etc/mysql/conf.d -v /opt/Docker/slavedb/data:/var/lib/mysql --link masterdb:mysql -e MYSQL_ROOT_PASSWORD=mysecretpass -d percona:5.6
--
--
--  sudo docker exec -ti slavedb 'mysql' -uroot -pmysecretpass -e'change master to master_host="mysql",master_user="repl",master_password="slavepass",master_log_file="mysqld-bin.000004",master_log_pos=310;"' -vvv
--
--
--  sudo docker exec -ti slavedb 'mysql' -uroot -pmysecretpass -e"START SLAVE;" -vvv
--
--
--  sudo docker exec -ti slavedb 'mysql' -uroot -pmysecretpass -e"SHOW SLAVE STATUS" -vvv

-- sudo docker exec -ti masterdb 'mysql' -uroot -pmysecretpass -vvv -e"create database example"
-- sudo docker exec -ti masterdb 'mysql' -uroot -pmysecretpass -vvv -e"create table example.dummy (id varchar(10))"
-- sudo docker exec -ti slavedb 'mysql' -uroot -pmysecretpass -e"show tables in example" -vvv
-- sudo docker exec -ti masterdb 'mysql' -uroot -pmysecretpass -vvv -e"show tables in example;";



-- https://www.percona.com/blog/2016/03/30/docker-mysql-replication-101/
