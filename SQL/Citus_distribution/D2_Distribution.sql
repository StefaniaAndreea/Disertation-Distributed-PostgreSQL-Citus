-- STORE 
SELECT create_distributed_table('store_sales','ss_ticket_number');
SELECT create_distributed_table('store_returns','sr_ticket_number',colocate_with=> 'store_sales');  
 -- WEB 
 SELECT create_distributed_table('web_sales','ws_order_number');
 SELECT create_distributed_table('web_returns', 'wr_order_number',colocate_with => 'web_sales'); 
-- CATALOG 
SELECT create_distributed_table('catalog_sales','cs_order_number');
SELECT create_distributed_table('catalog_returns','cr_order_number',colocate_with=> 'catalog_sales');
-- INVENTORY 
SELECT create_distributed_table('inventory', 'inv_warehouse_sk'); 
