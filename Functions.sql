/*Function to check the seat status*/

DELIMITER $$
CREATE FUNCTION fn_seat_status(seatno VARCHAR(20)) RETURNS INT(11)
BEGIN
DECLARE states VARCHAR(20);
DECLARE flag INT;
SET states=(SELECT state FROM seat_status WHERE seat_id=(SELECT id FROM seat WHERE Seats=seatno));
IF(states='Available')
THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END $$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Function to check if the seat is valid*/

DELIMITER $$
CREATE  FUNCTION fn_check_seat(seat_no VARCHAR(20)) RETURNS INT(11)
BEGIN
DECLARE flag INT;
IF EXISTS(SELECT Seats FROM seat WHERE Seats=seat_no) THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END$$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Function to check if the item is valid*/

DELIMITER $$
CREATE  FUNCTION fn_check_item(item VARCHAR(20)) RETURNS INT(11)
BEGIN
DECLARE flag INT;
IF EXISTS(SELECT food_list FROM menu WHERE food_list=item) THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END$$
DELIMITER ;
------------------------------------------------------------------------------------------------------------------------------------------
/*Function to check if the service is available at the given time*/

DELIMITER $$
CREATE  FUNCTION fn_check_time(given_time TIME) RETURNS INT(11)
BEGIN
DECLARE flag INT;
IF EXISTS(SELECT id FROM tab_food_type WHERE given_time BETWEEN from_time AND to_time) THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END$$
DELIMITER ;
---------------------------------------------------------------------------------------------------------------------------------------------
/*Function to check if the food item is available in the given time*/

DELIMITER $$
CREATE  FUNCTION fn_check_item_serving_time(item_type INT, ordered_time TIME) RETURNS INT(11)
BEGIN
DECLARE flag INT;
IF(item_type IN (SELECT id FROM tab_food_type WHERE tab_food_type.`from_time` <=ordered_time  AND tab_food_type.`to_time`>=ordered_time )) THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END$$
DELIMITER ;
-------------------------------------------------------------------------------------------------------------------------------------------
/*Function to check if the quantity is valid*/

DELIMITER $$
CREATE  FUNCTION fn_quantity_valid(quant SMALLINT,item_id INT,item_type INT) RETURNS INT(11)
BEGIN
DECLARE flag INT;
IF (quant>0 AND quant<=(SELECT quantity FROM tab_menu_order WHERE menu_list=item_id AND food_type=item_type)) THEN
SET flag=1;
ELSE
SET flag=0;
END IF;
RETURN flag;
END$$
DELIMITER ;