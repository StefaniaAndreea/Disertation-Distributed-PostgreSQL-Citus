============================================================
DEFINIREA CHEILOR PRIMARE 
============================================================
------------------------------------------------------------
A. TABELE DE DIMENSIUNI 
------------------------------------------------------------
ALTER TABLE date_dim ADD PRIMARY KEY (d_date_sk);
ALTER TABLE time_dim ADD PRIMARY KEY (t_time_sk);
ALTER TABLE item ADD PRIMARY KEY (i_item_sk);
ALTER TABLE customer ADD PRIMARY KEY (c_customer_sk);
ALTER TABLE customer_demographics ADD PRIMARY KEY (cd_demo_sk);
ALTER TABLE household_demographics ADD PRIMARY KEY (hd_demo_sk);
ALTER TABLE customer_address ADD PRIMARY KEY (ca_address_sk);
ALTER TABLE store ADD PRIMARY KEY (s_store_sk);
ALTER TABLE warehouse ADD PRIMARY KEY (w_warehouse_sk);
ALTER TABLE promotion ADD PRIMARY KEY (p_promo_sk);
ALTER TABLE reason ADD PRIMARY KEY (r_reason_sk);
ALTER TABLE income_band ADD PRIMARY KEY (ib_income_band_sk);
ALTER TABLE call_center ADD PRIMARY KEY (cc_call_center_sk);
ALTER TABLE web_page ADD PRIMARY KEY (wp_web_page_sk);
ALTER TABLE catalog_page ADD PRIMARY KEY (cp_catalog_page_sk);
ALTER TABLE web_site ADD PRIMARY KEY (web_site_sk);
ALTER TABLE ship_mode ADD PRIMARY KEY (sm_ship_mode_sk);

------------------------------------------------------------
B. TABELE DE FAPTE 
------------------------------------------------------------
-- STORE CHANNEL
ALTER TABLE store_sales ADD PRIMARY KEY (ss_item_sk, ss_ticket_number);
ALTER TABLE store_returns ADD PRIMARY KEY (sr_item_sk, sr_ticket_number);

-- CATALOG CHANNEL
ALTER TABLE catalog_sales ADD PRIMARY KEY (cs_item_sk, cs_order_number);
ALTER TABLE catalog_returns ADD PRIMARY KEY (cr_item_sk, cr_order_number);

-- WEB CHANNEL
ALTER TABLE web_sales ADD PRIMARY KEY (ws_item_sk, ws_order_number);
ALTER TABLE web_returns ADD PRIMARY KEY (wr_item_sk, wr_order_number);

-- INVENTORY
ALTER TABLE inventory ADD PRIMARY KEY (inv_date_sk, inv_item_sk, inv_warehouse_sk);

============================================================
DEFINIREA CHEILOR STRAINE  ============================================================
------------------------------------------------------------
A. DIMENSION -> DIMENSION 
------------------------------------------------------------
ALTER TABLE customer ADD CONSTRAINT fk_c_cdemo FOREIGN KEY (c_current_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE customer ADD CONSTRAINT fk_c_hdemo FOREIGN KEY (c_current_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE customer ADD CONSTRAINT fk_c_addr FOREIGN KEY (c_current_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE customer ADD CONSTRAINT fk_c_first_sales_date FOREIGN KEY (c_first_sales_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE customer ADD CONSTRAINT fk_c_first_shipto_date FOREIGN KEY (c_first_shipto_date_sk) REFERENCES date_dim (d_date_sk);

ALTER TABLE household_demographics ADD CONSTRAINT fk_hd_income FOREIGN KEY (hd_income_band_sk) REFERENCES income_band (ib_income_band_sk);

ALTER TABLE store ADD CONSTRAINT fk_s_close_date FOREIGN KEY (s_closed_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE call_center ADD CONSTRAINT fk_cc_open_date FOREIGN KEY (cc_open_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE call_center ADD CONSTRAINT fk_cc_closed_date FOREIGN KEY (cc_closed_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_site ADD CONSTRAINT fk_web_open_date FOREIGN KEY (web_open_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_site ADD CONSTRAINT fk_web_close_date FOREIGN KEY (web_close_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_page ADD CONSTRAINT fk_wp_creation_date FOREIGN KEY (wp_creation_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_page ADD CONSTRAINT fk_wp_access_date FOREIGN KEY (wp_access_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_page ADD CONSTRAINT fk_wp_customer FOREIGN KEY (wp_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE catalog_page ADD CONSTRAINT fk_cp_start_date FOREIGN KEY (cp_start_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE catalog_page ADD CONSTRAINT fk_cp_end_date FOREIGN KEY (cp_end_date_sk) REFERENCES date_dim (d_date_sk);

------------------------------------------------------------
B. FACT -> DIMENSION 
------------------------------------------------------------
-- STORE_SALES
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_item FOREIGN KEY (ss_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_date FOREIGN KEY (ss_sold_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_time FOREIGN KEY (ss_sold_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_customer FOREIGN KEY (ss_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_cdemo FOREIGN KEY (ss_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_hdemo FOREIGN KEY (ss_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_addr FOREIGN KEY (ss_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_store FOREIGN KEY (ss_store_sk) REFERENCES store (s_store_sk);
ALTER TABLE store_sales ADD CONSTRAINT fk_ss_promo FOREIGN KEY (ss_promo_sk) REFERENCES promotion (p_promo_sk);

-- STORE_RETURNS
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_returned_date FOREIGN KEY (sr_returned_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_return_time FOREIGN KEY (sr_return_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_item FOREIGN KEY (sr_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_customer FOREIGN KEY (sr_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_cdemo FOREIGN KEY (sr_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_hdemo FOREIGN KEY (sr_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_addr FOREIGN KEY (sr_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_store FOREIGN KEY (sr_store_sk) REFERENCES store (s_store_sk);
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_reason FOREIGN KEY (sr_reason_sk) REFERENCES reason (r_reason_sk);

-- WEB_SALES
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_sold_date FOREIGN KEY (ws_sold_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_sold_time FOREIGN KEY (ws_sold_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_date FOREIGN KEY (ws_ship_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_item FOREIGN KEY (ws_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_bill_customer FOREIGN KEY (ws_bill_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_bill_cdemo FOREIGN KEY (ws_bill_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_bill_hdemo FOREIGN KEY (ws_bill_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_bill_addr FOREIGN KEY (ws_bill_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_customer FOREIGN KEY (ws_ship_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_cdemo FOREIGN KEY (ws_ship_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_hdemo FOREIGN KEY (ws_ship_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_addr FOREIGN KEY (ws_ship_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_web_page FOREIGN KEY (ws_web_page_sk) REFERENCES web_page (wp_web_page_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_web_site FOREIGN KEY (ws_web_site_sk) REFERENCES web_site (web_site_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_ship_mode FOREIGN KEY (ws_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_warehouse FOREIGN KEY (ws_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);
ALTER TABLE web_sales ADD CONSTRAINT fk_ws_promo FOREIGN KEY (ws_promo_sk) REFERENCES promotion (p_promo_sk);

-- WEB_RETURNS
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returned_date FOREIGN KEY (wr_returned_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returned_time FOREIGN KEY (wr_returned_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_item FOREIGN KEY (wr_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_refunded_customer FOREIGN KEY (wr_refunded_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_refunded_cdemo FOREIGN KEY (wr_refunded_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_refunded_hdemo FOREIGN KEY (wr_refunded_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_refunded_addr FOREIGN KEY (wr_refunded_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returning_customer FOREIGN KEY (wr_returning_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returning_cdemo FOREIGN KEY (wr_returning_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returning_hdemo FOREIGN KEY (wr_returning_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_returning_addr FOREIGN KEY (wr_returning_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_web_page FOREIGN KEY (wr_web_page_sk) REFERENCES web_page (wp_web_page_sk);
ALTER TABLE web_returns ADD CONSTRAINT fk_wr_reason FOREIGN KEY (wr_reason_sk) REFERENCES reason (r_reason_sk);

-- CATALOG_SALES
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_sold_date FOREIGN KEY (cs_sold_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_sold_time FOREIGN KEY (cs_sold_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_date FOREIGN KEY (cs_ship_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_item FOREIGN KEY (cs_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_bill_customer FOREIGN KEY (cs_bill_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_bill_cdemo FOREIGN KEY (cs_bill_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_bill_hdemo FOREIGN KEY (cs_bill_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_bill_addr FOREIGN KEY (cs_bill_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_customer FOREIGN KEY (cs_ship_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_cdemo FOREIGN KEY (cs_ship_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_hdemo FOREIGN KEY (cs_ship_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_addr FOREIGN KEY (cs_ship_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_call_center FOREIGN KEY (cs_call_center_sk) REFERENCES call_center (cc_call_center_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_catalog_page FOREIGN KEY (cs_catalog_page_sk) REFERENCES catalog_page (cp_catalog_page_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_ship_mode FOREIGN KEY (cs_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_warehouse FOREIGN KEY (cs_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);
ALTER TABLE catalog_sales ADD CONSTRAINT fk_cs_promo FOREIGN KEY (cs_promo_sk) REFERENCES promotion (p_promo_sk);

-- CATALOG_RETURNS
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returned_date FOREIGN KEY (cr_returned_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returned_time FOREIGN KEY (cr_returned_time_sk) REFERENCES time_dim (t_time_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_item FOREIGN KEY (cr_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_refunded_customer FOREIGN KEY (cr_refunded_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_refunded_cdemo FOREIGN KEY (cr_refunded_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_refunded_hdemo FOREIGN KEY (cr_refunded_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_refunded_addr FOREIGN KEY (cr_refunded_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returning_customer FOREIGN KEY (cr_returning_customer_sk) REFERENCES customer (c_customer_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returning_cdemo FOREIGN KEY (cr_returning_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returning_hdemo FOREIGN KEY (cr_returning_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_returning_addr FOREIGN KEY (cr_returning_addr_sk) REFERENCES customer_address (ca_address_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_call_center FOREIGN KEY (cr_call_center_sk) REFERENCES call_center (cc_call_center_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_catalog_page FOREIGN KEY (cr_catalog_page_sk) REFERENCES catalog_page (cp_catalog_page_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_ship_mode FOREIGN KEY (cr_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_warehouse FOREIGN KEY (cr_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);
ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_reason FOREIGN KEY (cr_reason_sk) REFERENCES reason (r_reason_sk);

-- INVENTORY
ALTER TABLE inventory ADD CONSTRAINT fk_inv_item FOREIGN KEY (inv_item_sk) REFERENCES item (i_item_sk);
ALTER TABLE inventory ADD CONSTRAINT fk_inv_date FOREIGN KEY (inv_date_sk) REFERENCES date_dim (d_date_sk);
ALTER TABLE inventory ADD CONSTRAINT fk_inv_warehouse FOREIGN KEY (inv_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);

-- ------------------------------------------------------------
-- C. FACT -> FACT 
-- ------------------------------------------------------------
ALTER TABLE store_returns ADD CONSTRAINT fk_sr_sales 
    FOREIGN KEY (sr_item_sk, sr_ticket_number) 
    REFERENCES store_sales (ss_item_sk, ss_ticket_number);

ALTER TABLE web_returns ADD CONSTRAINT fk_wr_sales 
    FOREIGN KEY (wr_item_sk, wr_order_number) 
    REFERENCES web_sales (ws_item_sk, ws_order_number);

ALTER TABLE catalog_returns ADD CONSTRAINT fk_cr_sales 
    FOREIGN KEY (cr_item_sk, cr_order_number) 
    REFERENCES catalog_sales (cs_item_sk, cs_order_number);
