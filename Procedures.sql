/*Procedure to make the order*/

DELIMITER $$
CREATE PROCEDURE proc_make_order(seatno VARCHAR(20),IN _list1 MEDIUMTEXT,IN _list2 MEDIUMTEXT,order_time TIME)
    
    BEGIN
          DECLARE _next1 TEXT DEFAULT NULL ;
          DECLARE _nextlen1 INT DEFAULT NULL;
          DECLARE _value1 TEXT DEFAULT NULL;
          DECLARE _next2 TEXT DEFAULT NULL ;
          DECLARE _nextlen2 INT DEFAULT NULL;
          DECLARE _value2 TEXT DEFAULT NULL;
          DECLARE counter INT;
          DECLARE local_order_id INT;
	  SET local_order_id=FLOOR(100+RAND()*(900));
          SET counter=0;
       IF LENGTH(TRIM(_list1)) = 0 OR _list1 IS NULL OR LENGTH(TRIM(_list2)) = 0 OR _list2 IS NULL THEN
       SELECT "Place a valid order" AS Message;
       ELSE
/*Check for seat Availability*/
          IF(seat_status(seatno)=1)
          THEN
          
         UPDATE seat_status
         SET state='UnAvailable'
         WHERE seat_id=(SELECT id FROM seat WHERE Seats=seatno);
         
         iterator :
         LOOP    
            IF LENGTH(TRIM(_list1)) = 0 OR _list1 IS NULL OR LENGTH(TRIM(_list2)) = 0 OR _list2 IS NULL THEN
            LEAVE iterator;
              END IF;  
                 SET _next1 = SUBSTRING_INDEX(_list1,',',1);
                 SET _nextlen1 = LENGTH(_next1);
                 SET _value1 = TRIM(_next1);
                 
                 SET _next2 = SUBSTRING_INDEX(_list2,',',1);
                 SET _nextlen2 = LENGTH(_next2);
                 SET _value2 = TRIM(_next2);
  /*Check whether the ordered item is less than 5*/                 
		 SET counter=counter+1;
                 IF(counter>(SELECT order_limit FROM tab_order_limit))
                 THEN
                 SELECT 'You can choose only 5 items' AS message;
                 ELSE
  /*Call the procedure foodOrder to order the items for requested seats*/ 
		 CALL proc_process_order(local_order_id,seatno,_next1,_next2,CURRENT_TIME);
		 DO SLEEP(10);
		 SELECT * FROM food_transaction;
                 END IF;           
                 SET _list1 = INSERT(_list1,1,_nextlen1 + 1,'');
                 SET _list2 = INSERT(_list2,1,_nextlen2 + 1,'');

         END LOOP; 
       ELSE
       SELECT 'Seat UnAvailable' AS message;      
       END IF;
         UPDATE seat_status
         SET state='Available'
         WHERE seat_id=(SELECT id FROM seat WHERE Seats=seatno);
         END IF;     
    END$$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to process the order*/

DELIMITER $$
CREATE PROCEDURE proc_process_order(local_id INT,seatno VARCHAR(20),item VARCHAR(20),quant SMALLINT,ordered_time TIME)
BEGIN
DECLARE seat INT;
DECLARE local_item VARCHAR(20);
DECLARE item_id INT;
DECLARE item_type INT;
DECLARE local_seat INT;
DECLARE given_time INT;

SET local_seat=(SELECT id FROM seat WHERE Seats=seatno );
SET item_id =     (SELECT id FROM menu WHERE menu.`food_list`=item);
SET item_type =   (SELECT food_type FROM tab_menu_order WHERE menu_list=item_id AND food_type IN
		(SELECT id FROM tab_food_type WHERE tab_food_type.`from_time` <=ordered_time  AND tab_food_type.`to_time`>=ordered_time ));	
SET local_item=check_item(item);
SET seat=check_seat(seatno);
SET given_time=check_time(ordered_time);
 /*Check whether the seat exists*/ 
IF(seat=1)
THEN
/*Check whether the item exists*/ 
IF(local_item=1)
THEN
/*Check whether the restaurant takes order in given time*/ 
IF (given_time=1)
THEN

/*Check whether the ordered item is served in respective session*/
IF(fn_check_item_serving_time(item_type,ordered_time))
	THEN

/*Check for the ordered quantity is available in stock*/
IF(fn_quantity_valid(quant,item_id,item_type))
THEN


	
	START TRANSACTION;
	SET Autocommit=0;
	INSERT INTO food_transaction(seat_no,ordered_item,quantity,ordered_time,state)VALUES(seatno,item,quant,ordered_time,'Ordered');
	UPDATE tab_menu_order SET quantity=quantity-quant
	WHERE menu_list=item_id AND food_type=item_type;
	INSERT INTO order_details (order_id,seat_id,order_item) VALUES (local_id,local_seat,item_id);
	COMMIT;
	
ELSE
SELECT 'Invalid Quantity'AS message;
END IF;	
	
ELSE
SELECT 'Invalid Time.We dont serve those items now.' AS message;
END IF;
	
ELSE
SELECT 'We are not serving at a moment.Wait for next session' AS message;
END IF;

ELSE
SELECT 'Invalid Item. We dont serve that item.' AS message;
END IF;

ELSE
SELECT 'Invalid Seat no.Please choose the correct seat no(seat1-seat10)' AS message;
END IF;

END $$
DELIMITER ;
-------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to add a new food item to the menu*/

DELIMITER $$
CREATE PROCEDURE proc_add_food(id SMALLINT,item VARCHAR(20),food_type VARCHAR(20))
BEGIN
DECLARE new_food_type INT;
DECLARE new_menulist INT;
SET autocommit=0;
START TRANSACTION;
INSERT INTO menu VALUES(id,item);

SET new_menulist=(SELECT id FROM menu WHERE food_list=item);
SET new_food_type=(SELECT tab_food_type.`id` FROM tab_food_type WHERE tab_food_type.`type`=food_type);

INSERT INTO tab_menu_order(menu_list,food_type,quantity)
VALUES(new_menulist,new_food_type,(SELECT quantity FROM tab_food_type WHERE tab_food_type.`id`=new_food_type));

INSERT INTO food_stock(menu_list,food_type,quantity)
VALUES(new_menulist,new_food_type,(SELECT quantity FROM tab_food_type WHERE tab_food_type.`id`=new_food_type));

COMMIT;
END$$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to cancel the order*/

DELIMITER $$
CREATE PROCEDURE proc_cancel_order(seatno VARCHAR(20),item VARCHAR(20))
BEGIN
DECLARE item_id INT;
DECLARE item_type INT;
DECLARE local_ordered_time VARCHAR(20);
DECLARE local_qty INT;
DECLARE qty INT;
DECLARE local_ordered_item VARCHAR(20);
SET local_ordered_item=(SELECT  ordered_item FROM food_transaction WHERE seat_no=seatno AND ordered_item=item AND state='Ordered'
		ORDER BY ordered_time DESC LIMIT 0,1);
SET local_ordered_time=(SELECT  ordered_time FROM food_transaction WHERE seat_no=seatno AND ordered_item=local_ordered_item AND state='Ordered'
		ORDER BY ordered_time DESC LIMIT 0,1);
SET qty=(SELECT quantity FROM food_transaction WHERE seat_no=seatno AND ordered_item=item AND state='Ordered' ORDER BY ordered_time DESC LIMIT 0,1);
SET item_id = (SELECT id FROM menu WHERE food_list=item);
SET item_type = (SELECT food_type FROM tab_menu_order WHERE menu_list=item_id AND food_type IN
		 (SELECT id FROM tab_food_type WHERE tab_food_type.`from_time` <=local_ordered_time  AND tab_food_type.`to_time`>=local_ordered_time ));
		 
SET local_qty=(SELECT quantity FROM tab_menu_order WHERE menu_list=item_id AND food_type=item_type);
IF(local_qty<(SELECT quantity FROM tab_food_type WHERE id=item_type))
THEN
UPDATE food_transaction
SET quantity=0,state='Cancelled'
WHERE seat_no=seatno AND ordered_item=local_ordered_item AND ordered_time=local_ordered_time;
UPDATE tab_menu_order
SET quantity=quantity+qty
WHERE menu_list=item_id AND food_type=item_type ;
SELECT 'Order cancelled sucessfully' AS message;
END IF;
END $$
DELIMITER ;
---------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to view the particular order details*/

DELIMITER $$
CREATE PROCEDURE proc_view_order_details (l_order_id INT)
BEGIN
SELECT order_id,food_list FROM order_details
JOIN menu
WHERE order_id=l_order_id AND menu.`id`=order_details.`order_item`
ORDER BY order_id;
END $$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------