--SF10_N0
--similar for SF50_N0, SF100_N0
SET search_path TO sf10_n0;
COPY call_center FROM '/tmp/export_SF10/call_center.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY catalog_page FROM '/tmp/export_SF10/catalog_page.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY catalog_returns FROM '/tmp/export_SF10/catalog_returns.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY catalog_sales FROM '/tmp/export_SF10/catalog_sales.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY customer FROM '/tmp/export_SF10/customer.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY customer_address FROM '/tmp/export_SF10/customer_address.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY customer_demographics FROM '/tmp/export_SF10/customer_demographics.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY date_dim FROM '/tmp/export_SF10/date_dim.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY household_demographics FROM '/tmp/export_SF10/household_demographics.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY income_band FROM '/tmp/export_SF10/income_band.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY inventory FROM '/tmp/export_SF10/inventory.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY item FROM '/tmp/export_SF10/item.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY promotion FROM '/tmp/export_SF10/promotion.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY reason FROM '/tmp/export_SF10/reason.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY ship_mode FROM '/tmp/export_SF10/ship_mode.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY store FROM '/tmp/export_SF10/store.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY store_returns FROM '/tmp/export_SF10/store_returns.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY store_sales FROM '/tmp/export_SF10/store_sales.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY time_dim FROM '/tmp/export_SF10/time_dim.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY warehouse FROM '/tmp/export_SF10/warehouse.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY web_page FROM '/tmp/export_SF10/web_page.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY web_returns FROM '/tmp/export_SF10/web_returns.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY web_sales FROM '/tmp/export_SF10/web_sales.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');
COPY web_site FROM '/tmp/export_SF10/web_site.csv' WITH (FORMAT csv, DELIMITER '|', HEADER false, QUOTE '"');

