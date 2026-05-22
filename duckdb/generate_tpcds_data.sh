#!/bin/bash

# ============================================================
# Instalare DuckDB si generare date TPC-DS
# SF: SF10, SF50, SF100
# ============================================================

# ------------------------------------------------------------
# 1. Instalare utilitare necesare
# ------------------------------------------------------------

sudo apt-get update
sudo apt-get install -y unzip

# ------------------------------------------------------------
# 2. Descarcare DuckDB CLI
# ------------------------------------------------------------

wget https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip

# ------------------------------------------------------------
# 3. Dezarhivare DuckDB
# ------------------------------------------------------------

unzip duckdb_cli-linux-amd64.zip

# ============================================================
# GENERARE SF10
# ============================================================

mkdir /tmp/export_SF10

./duckdb /tmp/temp_sf10.duckdb 

INSTALL tpcds;
LOAD tpcds;

CALL dsdgen(sf=10);

EXPORT DATABASE '/tmp/export_SF10'
(FORMAT CSV, DELIMITER '|', HEADER FALSE);

.quit


rm /tmp/temp_sf10.duckdb

# ============================================================
# GENERARE SF50
# ============================================================

mkdir /tmp/export_SF50

./duckdb /tmp/temp_sf50.duckdb 

INSTALL tpcds;
LOAD tpcds;

CALL dsdgen(sf=50);

EXPORT DATABASE '/tmp/export_SF50'
(FORMAT CSV, DELIMITER '|', HEADER FALSE);

.quit

rm /tmp/temp_sf50.duckdb

# ============================================================
# GENERARE SF100
# ============================================================

mkdir /tmp/export_SF100

./duckdb /tmp/temp_sf100.duckdb 

INSTALL tpcds;
LOAD tpcds;

CALL dsdgen(sf=100);

EXPORT DATABASE '/tmp/export_SF100'
(FORMAT CSV, DELIMITER '|', HEADER FALSE);

.quit

rm /tmp/temp_sf100.duckdb