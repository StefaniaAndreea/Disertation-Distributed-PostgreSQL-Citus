-- STORE
SELECT create_distributed_table('store_sales','ss_item_sk');
SELECT create_distributed_table('store_returns','sr_item_sk',colocate_with => 'store_sales');
-- WEB
SELECT create_distributed_table('web_sales','ws_item_sk', colocate_with => 'store_sales');
SELECT create_distributed_table('web_returns','wr_item_sk', colocate_with => 'store_sales');
-- CATALOG
SELECT create_distributed_table('catalog_sales','cs_item_sk',colocate_with => 'store_sales');
SELECT create_distributed_table('catalog_returns','cr_item_sk',colocate_with => 'store_sales');
-- INVENTORY
SELECT create_distributed_table('inventory', 'inv_item_sk', colocate_with => 'store_sales');.
