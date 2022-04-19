CREATE DATABASE `treasuretables` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

CREATE USER `dotnetuser`@`localhost` IDENTIFIED BY 'password';

use treasuretables;

CREATE TABLE `sequence` (
  `i` int NOT NULL,
  PRIMARY KEY (`i`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `itemdescription` (
  `itemid` int NOT NULL AUTO_INCREMENT,
  `languageid` varchar(45) NOT NULL,
  `name` tinytext,
  `description` mediumtext,
  PRIMARY KEY (`itemid`,`languageid`)
) ENGINE=InnoDB AUTO_INCREMENT=514 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `item` (
  `itemid` int NOT NULL,
  `itemvalue` int DEFAULT '0',
  `containerid` int DEFAULT NULL,
  `comment` tinytext,
  `virtual` tinyint DEFAULT NULL,
  PRIMARY KEY (`itemid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `container` (
  `containerid` int NOT NULL,
  `containergroupid` int NOT NULL,
  `chance` int DEFAULT NULL,
  `comment` tinytext,
  PRIMARY KEY (`containerid`,`containergroupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



CREATE TABLE `containeditems` (
  `containeditemid` int NOT NULL AUTO_INCREMENT,
  `containerid` int NOT NULL,
  `containergroupid` int NOT NULL,
  `itemid` int NOT NULL,
  `m` int DEFAULT NULL COMMENT 'm * (sum(roll n d-sided dice)) + b',
  `n` int DEFAULT NULL COMMENT 'm * (sum(roll n d-sided dice)) + b',
  `d` int DEFAULT NULL COMMENT 'm * (sum(roll n d-sided dice)) + b',
  `b` int DEFAULT NULL COMMENT 'm * (sum(roll n d-sided dice)) + b',
  PRIMARY KEY (`containeditemid`)
) ENGINE=InnoDB AUTO_INCREMENT=550 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `rollcontainer`(containeridchoice int) RETURNS int
BEGIN
declare output int;
WITH bins as (
SELECT containergroupid, 
lag(binmax, 1, 0) OVER (ORDER BY containergroupid) + 1 as binmin,
binmax
FROM (
SELECT containergroupid, 
(SUM(chance) OVER (ORDER BY containergroupid)) as binmax
FROM treasuretables.container where containerid = containeridchoice
) as binmaxtable), 
selection as (SELECT FLOOR(RAND() * (MAX(binmax)-MIN(binmin)+1) + 1) roll FROM bins) 
SELECT containergroupid into output from selection
INNER JOIN bins on selection.roll between bins.binmin and bins.binmax;
RETURN output;
END$$
DELIMITER ;


DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `rolldice`(n int, d int) RETURNS int
    DETERMINISTIC
BEGIN
DECLARE output int;
WITH RECURSIVE cte AS (
	SELECT 1 as x, RAND() as r
    UNION ALL
    SELECT x + 1, RAND() FROM cte where x < n
)
SELECT CASE WHEN n IS NULL OR n = 0 OR d is NULL or d = 0 THEN 0 ELSE sum(floor(r*d)+1) END into output from cte;
RETURN output;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `rollamount`(m int, n int, d int, b int) RETURNS int
    DETERMINISTIC
BEGIN
declare output int;
SELECT CASE WHEN m is NULL or m = 0 or n is NULL or n = 0 or d is NULL or d = 0 THEN 0 ELSE m * rolldice(n,d) END + b into output;
RETURN output;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `rollitemamount`(containeditemid int) RETURNS int
    DETERMINISTIC
BEGIN
DECLARE output int;
SELECT rollamount(m,n,d,b) INTO output
FROM containeditems where containeditems.containeditemid = containeditemid;
RETURN output;
END$$
DELIMITER ;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `rollitemamountview` AS select `containeditems`.`containeditemid` AS `containeditemid`,`ROLLITEMAMOUNT`(`containeditems`.`containeditemid`) AS `rollitemamount` from `containeditems`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listallitems`()
BEGIN
SELECT item.itemid id, itemdescription.`name` `name`, itemdescription.`description` `description`, item.itemvalue `value`,
CASE WHEN item.containerid is NULL THEN 0 ELSE 1 END `iscontainer`,
CASE WHEN item.`virtual` is NULL or item.`virtual` <> 1 THEN 0 ELSE item.`virtual` END `virtual`
FROM item
LEFT OUTER JOIN itemdescription on item.itemid = itemdescription.itemid;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listcontainers`()
BEGIN
SELECT item.itemid id, itemdescription.`name` `name`, itemdescription.`description` `description`, item.itemvalue `value`,
CASE WHEN item.containerid is NULL THEN 0 ELSE 1 END `iscontainer`,
CASE WHEN item.`virtual` is NULL or item.`virtual` <> 1 THEN 0 ELSE item.`virtual` END `virtual`
FROM item
LEFT OUTER JOIN itemdescription on item.itemid = itemdescription.itemid
WHERE item.containerid IS NOT NULL;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `rolltreasure`(n int, id int, lang int)
BEGIN
WITH RECURSIVE cte AS (
SELECT sequence.i, item.itemid as itemid, item.containerid as containerid, rollcontainer(item.containerid) as containergroupid, CASE WHEN item.containerid IS NULL THEN n ELSE 1 END as amount from item
INNER JOIN sequence on sequence.i <= CASE WHEN item.containerid IS NULL THEN 1 ELSE n END
where item.itemid = id
UNION ALL
SELECT sequence.i, item.itemid as itemid, item.containerid as containerid, rollcontainer(item.containerid) as containergroupid, CASE WHEN item.containerid IS NULL THEN rollitemamountview.rollitemamount ELSE 1 END as amount FROM cte
INNER JOIN containeditems on containeditems.containerid = cte.containerid and containeditems.containergroupid = cte.containergroupid
INNER JOIN item on containeditems.itemid = item.itemid
INNER JOIN rollitemamountview on rollitemamountview.containeditemid = containeditems.containeditemid
INNER JOIN sequence on sequence.i <= CASE WHEN item.containerid IS NULL THEN 1 ELSE rollitemamountview.rollitemamount END
),
results as (SELECT cte.itemid itemid, SUM(cte.amount) amount FROM cte INNER JOIN item on item.itemid = cte.itemid WHERE item.`virtual` IS NULL or item.`virtual` <> 1 GROUP BY itemid)
SELECT results.itemid as id, CAST(results.amount as SIGNED INT) as amount, itemdescription.`name` `name`, itemdescription.`description` `description`, item.itemvalue `value` FROM results
LEFT OUTER JOIN item on item.itemid = results.itemid
LEFT OUTER JOIN itemdescription on item.itemid = itemdescription.itemid and itemdescription.languageid = lang;
END$$
DELIMITER ;
