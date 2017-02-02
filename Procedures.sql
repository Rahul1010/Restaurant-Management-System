/*Procedure to make the order*/

DELIMITER $$
CREATE PROCEDURE proc_make_order(seatno VARCHAR(20),IN _list1 MEDIUMTEXT,IN _list2 MEDIUMTEXT,order_time TIME,OUT comments VARCHAR(200))
    
    BEGIN
          DECLARE _next1 TEXT DEFAULT NULL ;
          DECLARE _nextlen1 INT DEFAULT NULL;
          
          DECLARE _value1 TEXT DEFAULT NULL;
          DECLARE _next2 TEXT DEFAULT NULL ;
          DECLARE _nextlen2 INT DEFAULT NULL;
          DECLARE _value2 TEXT DEFAULT NULL;
          DECLARE counter INT;
          DECLARE local_order_id INT;
	  SET counter=0;
          SET comments=" ";
        SET local_order_id=rand_no(); 
	START TRANSACTION;
	SET autocommit=0;

       IF LENGTH(TRIM(_list1)) = 0 OR _list1 IS NULL OR LENGTH(TRIM(_list2)) = 0 OR _list2 IS NULL THEN
       SELECT "Place a valid order" INTO comments;
	         SELECT comments;
       ELSE
/*Check for seat Availability*/
          IF(fn_seat_status(seatno)=1)
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
                 SELECT 'You can choose only 5 items'  INTO comments;
	         SELECT comments;
                 ELSE
  /*Call the procedure foodOrder to order the items for requested seats*/ 
		 CALL proc_process_order(local_order_id,seatno,_next1,_next2,CURRENT_TIME,@message);
		 SET comments=CONCAT(comments,"|",@message);
		 SELECT comments;
                 END IF;           
                 SET _list1 = INSERT(_list1,1,_nextlen1 + 1,'');
                 SET _list2 = INSERT(_list2,1,_nextlen2 + 1,'');

         END LOOP; 
       ELSE
       SELECT 'Seat UnAvailable' INTO comments;
	         SELECT comments;
       END IF;
         UPDATE seat_status
         SET state='Available',user_state=FALSE
         WHERE seat_id=(SELECT id FROM seat WHERE Seats=seatno);
         END IF; 
         COMMIT;    
    END$$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to process the order*/

/*Procedure that processess the order*/
DELIMITER $$
CREATE PROCEDURE proc_process_order(local_id INT,seatno VARCHAR(20),item VARCHAR(20),quant SMALLINT,ordered_time TIME,OUT message VARCHAR(200))
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
	INSERT INTO food_transaction(ordered_id,seat_no,ordered_item,quantity,ordered_time,ordered_date,state)VALUES(local_id,seatno,item,quant,ordered_time,CURRENT_DATE,'Ordered');
	UPDATE tab_menu_order SET quantity=quantity-quant
	WHERE menu_list=item_id AND food_type=item_type;
	SELECT 'Order placed successfully' INTO message;
	SELECT message;
	COMMIT;
	
ELSE
SELECT 'Invalid Quantity' INTO message;
SELECT message;
END IF;	
	
ELSE
SELECT 'Invalid Time.We dont serve those items now.'  INTO message;
SELECT message;
END IF;
	
ELSE
SELECT 'We are not serving at a moment.Wait for next session'  INTO message;
SELECT message;
END IF;

ELSE
SELECT 'Invalid Item. We dont serve that item.'  INTO message;
SELECT message;
END IF;

ELSE
SELECT 'Invalid Seat no.Please choose the correct seat no(seat1-seat10)'  INTO message;
SELECT message;
END IF;

END $$
DELIMITER ;
-------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to add a new food item to the menu*/

DELIMITER $$
CREATE PROCEDURE proc_add_food(id SMALLINT,item VARCHAR(20),food_type VARCHAR(20),OUT add_food_message VARCHAR(200))
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

SELECT 'Food added successfully' INTO add_food_message;
SELECT add_food_message;

COMMIT;
END$$
DELIMITER ;
--------------------------------------------------------------------------------------------------------------------------------------------
/*Procedure to cancel the order*/

DELIMITER $$
CREATE PROCEDURE proc_cancel_order(order_id INT,seatno VARCHAR(20),item VARCHAR(20),OUT cancel_comments VARCHAR(200))
BEGIN
DECLARE item_id INT;
DECLARE item_type INT;
DECLARE local_ordered_time VARCHAR(20);
DECLARE local_qty INT;
DECLARE qty INT;
DECLARE local_ordered_item VARCHAR(20);
SET local_ordered_item=(SELECT  ordered_item FROM food_transaction WHERE ordered_id=order_id AND  seat_no=seatno AND ordered_item=item AND state='Ordered' AND ordered_date=CURRENT_DATE
		ORDER BY ordered_time DESC LIMIT 0,1);
SET local_ordered_time=(SELECT  ordered_time FROM food_transaction WHERE ordered_id=order_id AND seat_no=seatno AND ordered_item=local_ordered_item AND state='Ordered' AND ordered_date=CURRENT_DATE
		ORDER BY ordered_time DESC LIMIT 0,1);
SET qty=(SELECT quantity FROM food_transaction WHERE ordered_id=order_id AND seat_no=seatno AND ordered_item=item AND state='Ordered' AND ordered_date=CURRENT_DATE ORDER BY ordered_time DESC LIMIT 0,1);
SET item_id = (SELECT id FROM menu WHERE food_list=item);
SET item_type = (SELECT food_type FROM tab_menu_order WHERE menu_list=item_id AND food_type IN
		 (SELECT id FROM tab_food_type WHERE tab_food_type.`from_time` <=local_ordered_time  AND tab_food_type.`to_time`>=local_ordered_time ));
		 
SET local_qty=(SELECT quantity FROM tab_menu_order WHERE menu_list=item_id AND food_type=item_type );
IF order_id IN(SELECT ordered_id FROM food_transaction)
THEN
IF (local_qty<(SELECT quantity FROM tab_food_type WHERE id=item_type))
THEN
START TRANSACTION;
SET autocommit=0;
UPDATE food_transaction
SET quantity=0,state='Cancelled'
WHERE ordered_id=order_id AND seat_no=seatno AND ordered_item=local_ordered_item AND ordered_time=local_ordered_time;
UPDATE tab_menu_order
SET quantity=quantity+qty
WHERE menu_list=item_id AND food_type=item_type ;
SELECT 'Order cancelled sucessfully' INTO cancel_comments;
SELECT cancel_comments;
COMMIT;
ELSE
SELECT 'You cant cancel'INTO cancel_comments;
SELECT cancel_comments;
END IF;
ELSE
SELECT 'There is no such order id.'INTO cancel_comments;
SELECT cancel_comments;
END IF;
COMMIT;
END $$
DELIMITER ;