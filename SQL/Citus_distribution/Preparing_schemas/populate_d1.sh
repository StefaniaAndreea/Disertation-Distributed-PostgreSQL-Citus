#!/bin/bash

# Utilizare: ./populate_d1.sh <scale_factor>

SF=$1
NW=$2

if [ -z "$SF" ] || [ -z "$NW" ]; then
    echo "Eroare: trebuie specificat scale factor-ul si numarul de workeri."
    echo "Utilizare: ./populate_d1.sh <scale_factor> <nr_workeri>"
    echo "Exemplu:   ./populate_d1.sh sf10 n2"
    echo "           ./populate_d1.sh sf50 n5"
    exit 1
fi

if [ "$NW" != "n2" ] && [ "$NW" != "n5" ]; then
    echo "Eroare: numarul de workeri trebuie sa fie n2 sau n5."
    exit 1
fi

SCHEMA="${SF}_${NW}_d1"
SOURCE_SCHEMA="${SF}_n0"
LOG_FILE="populate_${SCHEMA}_$(date +%Y%m%d_%H%M%S).log"

echo "=============================================" | tee -a "$LOG_FILE"
echo "Inceput populare schema: $SCHEMA" | tee -a "$LOG_FILE"
echo "Sursa date: $SOURCE_SCHEMA" | tee -a "$LOG_FILE"
echo "Strategia: D1 (colocare globala pe item_sk)" | tee -a "$LOG_FILE"
echo "Nr. workeri: $NW" | tee -a "$LOG_FILE"
echo "Data/Ora: $(date)" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"

run_sql() {
    local DESCRIPTION=$1
    local SQL=$2
    echo "" | tee -a "$LOG_FILE"
    echo "[$(date +%H:%M:%S)] START: $DESCRIPTION" | tee -a "$LOG_FILE"
    result=$(sudo -i -u postgres psql -d tpcds -v ON_ERROR_STOP=1 -c "$SQL" 2>&1)
    status=$?
    echo "$result" | tee -a "$LOG_FILE"
    if [ $status -ne 0 ]; then
        echo "[$(date +%H:%M:%S)] EROARE la: $DESCRIPTION" | tee -a "$LOG_FILE"
        echo "Script oprit din cauza erorii." | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "[$(date +%H:%M:%S)] OK: $DESCRIPTION" | tee -a "$LOG_FILE"
}

run_sql_file() {
    local DESCRIPTION=$1
    local FILE=$2
    echo "" | tee -a "$LOG_FILE"
    echo "[$(date +%H:%M:%S)] START: $DESCRIPTION" | tee -a "$LOG_FILE"
    result=$(sudo -i -u postgres psql -d tpcds -v ON_ERROR_STOP=1 -v search_path="$SCHEMA" -c "SET search_path TO $SCHEMA;" -f "$FILE" 2>&1)
    status=$?
    echo "$result" | tee -a "$LOG_FILE"
    if [ $status -ne 0 ]; then
        echo "[$(date +%H:%M:%S)] EROARE la: $DESCRIPTION" | tee -a "$LOG_FILE"
        echo "Script oprit din cauza erorii." | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "[$(date +%H:%M:%S)] OK: $DESCRIPTION" | tee -a "$LOG_FILE"
}

# PASUL 1: Creare tabele 
echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 1: Creare tabele ---" | tee -a "$LOG_FILE"
run_sql_file "Creare tabele in schema $SCHEMA" "/tmp/creare_tabele.sql"

# PASUL 2: Reference tables (dimensiuni)
echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 2: Creare reference tables ---" | tee -a "$LOG_FILE"

for TABLE in date_dim time_dim item customer customer_address customer_demographics \
             household_demographics income_band store warehouse promotion reason \
             call_center web_site web_page catalog_page ship_mode; do
    run_sql "Reference table: $TABLE" "SET search_path TO $SCHEMA; SELECT create_reference_table('$TABLE');"
done

# # PASUL 3: Distributed tables - D1 

echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 3: Creare distributed tables D1 ---" | tee -a "$LOG_FILE"

run_sql "Distributed: store_sales (ancora D1)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('store_sales','ss_item_sk');"

run_sql "Distributed: store_returns (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('store_returns','sr_item_sk', colocate_with => 'store_sales');"

run_sql "Distributed: web_sales (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('web_sales','ws_item_sk', colocate_with => 'store_sales');"

run_sql "Distributed: web_returns (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('web_returns','wr_item_sk', colocate_with => 'store_sales');"

run_sql "Distributed: catalog_sales (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('catalog_sales','cs_item_sk', colocate_with => 'store_sales');"

run_sql "Distributed: catalog_returns (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('catalog_returns','cr_item_sk', colocate_with => 'store_sales');"

run_sql "Distributed: inventory (colocat cu store_sales)" \
    "SET search_path TO $SCHEMA; SELECT create_distributed_table('inventory','inv_item_sk', colocate_with => 'store_sales');"

# PASUL 4: Populare dimensiuni
echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 4: Populare dimensiuni ---" | tee -a "$LOG_FILE"

for TABLE in call_center catalog_page customer customer_address customer_demographics \
             date_dim household_demographics income_band item promotion reason \
             ship_mode store time_dim warehouse web_page web_site; do
    run_sql "Insert dimensiune: $TABLE" \
        "SET search_path TO $SCHEMA; INSERT INTO $TABLE SELECT * FROM ${SOURCE_SCHEMA}.${TABLE};"
done

# # PASUL 5: Populare tabele de fapte

echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 5: Populare tabele de fapte ---" | tee -a "$LOG_FILE"

run_sql "Insert facts: inventory" \
    "SET search_path TO $SCHEMA; INSERT INTO inventory SELECT * FROM ${SOURCE_SCHEMA}.inventory;"

run_sql "Insert facts: catalog_returns" \
    "SET search_path TO $SCHEMA; INSERT INTO catalog_returns SELECT * FROM ${SOURCE_SCHEMA}.catalog_returns;"

run_sql "Insert facts: catalog_sales" \
    "SET search_path TO $SCHEMA; INSERT INTO catalog_sales SELECT * FROM ${SOURCE_SCHEMA}.catalog_sales;"

run_sql "Insert facts: web_returns" \
    "SET search_path TO $SCHEMA; INSERT INTO web_returns SELECT * FROM ${SOURCE_SCHEMA}.web_returns;"

run_sql "Insert facts: web_sales" \
    "SET search_path TO $SCHEMA; INSERT INTO web_sales SELECT * FROM ${SOURCE_SCHEMA}.web_sales;"

run_sql "Insert facts: store_returns" \
    "SET search_path TO $SCHEMA; INSERT INTO store_returns SELECT * FROM ${SOURCE_SCHEMA}.store_returns;"

run_sql "Insert facts: store_sales" \
    "SET search_path TO $SCHEMA; INSERT INTO store_sales SELECT * FROM ${SOURCE_SCHEMA}.store_sales;"


# PASUL 6: Aplicare constrangeri
echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 6: Aplicare constrangeri ---" | tee -a "$LOG_FILE"
run_sql_file "Aplicare constraints" "/tmp/constraints.sql"

# PASUL 7: Verificare finala

echo "" | tee -a "$LOG_FILE"
echo "--- PASUL 7: Verificare finala ---" | tee -a "$LOG_FILE"

run_sql "Verificare conturi tabele" "SET search_path TO $SCHEMA; SELECT 'store_sales' as tabel, COUNT(*) FROM store_sales UNION ALL SELECT 'store_returns', COUNT(*) FROM store_returns UNION ALL SELECT 'web_sales', COUNT(*) FROM web_sales UNION ALL SELECT 'web_returns', COUNT(*) FROM web_returns UNION ALL SELECT 'catalog_sales', COUNT(*) FROM catalog_sales UNION ALL SELECT 'catalog_returns', COUNT(*) FROM catalog_returns UNION ALL SELECT 'inventory', COUNT(*) FROM inventory ORDER BY tabel;"

echo "" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
echo "FINALIZAT CU SUCCES: $SCHEMA" | tee -a "$LOG_FILE"
echo "Data/Ora: $(date)" | tee -a "$LOG_FILE"
echo "Log salvat in: $LOG_FILE" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
