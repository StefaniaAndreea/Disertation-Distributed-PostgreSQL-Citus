import csv

fisier_intrare = 'queries.sql'
fisier_iesire = 'queries_jmeter.csv'

with open(fisier_intrare, 'r', encoding='utf-8') as f:
    continut = f.read()

queries = [q.strip() for q in continut.split(';') if q.strip()]

with open(fisier_iesire, 'w', encoding='utf-8', newline='') as f:

    writer = csv.writer(f, delimiter='~', quoting=csv.QUOTE_NONE, escapechar='\\')

    writer.writerow(['ID_Interogare', 'SQL_INLINE'])

    for index, query in enumerate(queries, start=1):
        id_query = f"Q{index:03d}"
        sql_final = f"{query};"

        sql_final = " ".join(sql_final.split())

        writer.writerow([id_query, sql_final])

