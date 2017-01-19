/*

						Restaurant Management System
						
Procedures
----------

proc_make_order()         ----------------------------------->   Procedure that is used to place the order
proc_process_order()      ----------------------------------->   Procedure that processess the order
proc_cancel_order()       ----------------------------------->   Procedure that cancels the placed order item by item
proc_view_order_details() ----------------------------------->   Procedure that displays the items ordered in a particular order
proc_add_food()           ----------------------------------->   Procedure to add new items to the menu

Functions
---------

fn_seat_status()             --------------------------------->   Function to check the seat status
fn_check_seat()              --------------------------------->   Function to check if the seat is valid
fn_check_item()              --------------------------------->   Function to check if the item is valid
fn_check_time()              --------------------------------->   Function to check if the service is available at the given time
fn_check_item_serving_time() --------------------------------->   Function to check if the food item is available in the given time
fn_quantity_valid()          --------------------------------->   Function to check if the quantity is valid

View
----

view_stock                   --------------------------------->   To view the remaining stock details

*/

CALL proc_make_order('seat2','Variety Rice,North Indian Thali','1,1',CURRENT_TIME)

CALL proc_cancel_order('seat4','Dosa');

SELECT * FROM view_stock

CALL view_order_details(931)

CALL proc_add_food(22,'Porattas','Dinner')