# ============================================================
# Query Metadata Extraction.R
# ============================================================

library(tidyverse)
library(janitor)
library(stringr)

# -----------------------------
# 1. Config
# -----------------------------

query_file <- "C:/Users/savas/TCP-DS/queries_jmeter.csv"
output_dir <- "C:/Users/savas/TCP-DS/R"

if (!file.exists(query_file)) {
  stop("Fisierul cu interogari nu exista. Verifica query_file.")
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

# -----------------------------
# 2. Lista tabele TPC-DS folosite pentru Nr_Tabele
# -----------------------------

tpcds_tables <- c(
  "store_sales", "store_returns",
  "catalog_sales", "catalog_returns",
  "web_sales", "web_returns",
  "inventory",
  "date_dim", "time_dim", "item",
  "customer", "customer_address", "customer_demographics",
  "household_demographics", "income_band",
  "store", "warehouse", "promotion", "reason",
  "call_center", "web_site", "web_page",
  "catalog_page", "ship_mode"
)

# -----------------------------
# 3. Functii helper
# -----------------------------

normalize_sql <- function(sql_text) {
  sql_text %>%
    str_replace_all("/\\*.*?\\*/", " ") %>%
    str_replace_all("--.*?(\\r?\\n|$)", " ") %>%
    str_to_lower() %>%
    str_replace_all("\\s+", " ") %>%
    str_squish()
}

count_tpcds_tables <- function(sql_norm) {
  sum(map_lgl(
    tpcds_tables,
    ~ str_detect(sql_norm, paste0("\\b", .x, "\\b"))
  ))
}

count_cte_defs <- function(sql_norm) {
  if (!str_detect(sql_norm, "^with\\b")) {
    return(0L)
  }
  
  str_count(
    sql_norm,
    "\\b[a-zA-Z_][a-zA-Z0-9_]*\\s+as\\s*\\(\\s*select\\b"
  )
}

count_subqueries <- function(sql_norm, nr_cte) {
  total_select_in_parentheses <- str_count(sql_norm, "\\(\\s*select\\b")
  max(0L, total_select_in_parentheses - nr_cte)
}

extract_aggregations <- function(sql_norm) {
  aggs <- str_extract_all(
    sql_norm,
    "\\b(sum|count|avg|min|max|stddev|variance)\\s*\\("
  )[[1]]
  
  aggs <- aggs %>%
    str_replace("\\s*\\($", "") %>%
    str_to_upper() %>%
    unique() %>%
    sort()
  
  if (length(aggs) == 0) {
    return("")
  }
  
  paste(aggs, collapse = ", ")
}

count_aggregation_occurrences <- function(sql_norm) {
  str_count(sql_norm, "\\b(sum|count|avg|min|max|stddev|variance)\\s*\\(")
}

extract_clause_text <- function(sql_norm, clause_name) {
  pattern <- paste0(
    "\\b", clause_name, "\\b\\s+",
    "(.*?)",
    "(?=\\bgroup\\s+by\\b|\\bhaving\\b|\\border\\s+by\\b|\\blimit\\b|",
    "\\bunion\\b|\\bexcept\\b|\\bintersect\\b|;|$)"
  )
  
  matches <- str_match_all(sql_norm, regex(pattern, dotall = TRUE))[[1]]
  
  if (nrow(matches) == 0) {
    return("")
  }
  
  matches[, 2] %>%
    str_squish() %>%
    paste(collapse = " ")
}

operator_patterns <- list(
  "IS NOT NULL" = "\\bis\\s+not\\s+null\\b",
  "IS NULL"     = "\\bis\\s+null\\b",
  "BETWEEN"     = "\\bbetween\\b",
  "IN"          = "\\bin\\s*\\(",
  "LIKE"        = "\\blike\\b",
  ">="          = ">=",
  "<="          = "<=",
  "<>"          = "<>",
  "!="          = "!=",
  "="           = "(?<![<>!=])=(?![=])",
  ">"           = "(?<![<>=])>(?![=])",
  "<"           = "(?<![<>=])<(?![=>])"
)

extract_operators <- function(clause_text) {
  if (is.na(clause_text) || clause_text == "") {
    return("")
  }
  
  ops <- names(operator_patterns)[
    map_lgl(operator_patterns, ~ str_detect(clause_text, regex(.x)))
  ]
  
  if (length(ops) == 0) {
    return("")
  }
  
  paste(ops, collapse = ", ")
}

count_operators <- function(clause_text) {
  if (is.na(clause_text) || clause_text == "") {
    return(0L)
  }
  
  sum(map_int(operator_patterns, ~ str_count(clause_text, regex(.x))))
}

collapse_unique_values <- function(x) {
  values <- x %>%
    discard(~ is.na(.x) || .x == "") %>%
    str_split(",\\s*") %>%
    unlist() %>%
    str_squish() %>%
    discard(~ .x == "") %>%
    unique() %>%
    sort()
  
  if (length(values) == 0) {
    return("Nu au fost identificate")
  }
  
  paste(values, collapse = ", ")
}

minmax_summary <- function(x) {
  paste0(
    "min=", min(x, na.rm = TRUE),
    "; max=", max(x, na.rm = TRUE)
  )
}

# -----------------------------
# 4. Citire fisier interogari
# -----------------------------

queries_raw <- read_delim(
  query_file,
  delim = "~",
  col_types = cols(.default = col_character()),
  trim_ws = TRUE,
  show_col_types = FALSE
) %>%
  clean_names()

if (!all(c("id_interogare", "sql_inline") %in% names(queries_raw))) {
  stop("Fisierul trebuie sa contina coloanele ID_Interogare si SQL_INLINE.")
}

# -----------------------------
# 5. Extragere metadate
# -----------------------------

query_metadata <- queries_raw %>%
  transmute(
    ID_Interogare = id_interogare,
    sql_norm = normalize_sql(sql_inline)
  ) %>%
  mutate(
    # Complexitate generala
    Nr_Tabele = map_int(sql_norm, count_tpcds_tables),
    Nr_JOIN = str_count(sql_norm, "\\bjoin\\b"),
    
    # Tipuri JOIN
    Nr_LEFT_JOIN  = str_count(sql_norm, "\\bleft\\s+(outer\\s+)?join\\b"),
    Nr_RIGHT_JOIN = str_count(sql_norm, "\\bright\\s+(outer\\s+)?join\\b"),
    Nr_FULL_JOIN  = str_count(sql_norm, "\\bfull\\s+(outer\\s+)?join\\b"),
    Nr_CROSS_JOIN = str_count(sql_norm, "\\bcross\\s+join\\b"),
    
    Nr_INNER_JOIN = pmax(
      0L,
      Nr_JOIN - Nr_LEFT_JOIN - Nr_RIGHT_JOIN - Nr_FULL_JOIN - Nr_CROSS_JOIN
    ),
    
    Nr_CTE = map_int(sql_norm, count_cte_defs),
    Nr_Subquery = map2_int(sql_norm, Nr_CTE, count_subqueries),
    
    # Clauze SQL
    Are_GROUP_BY = str_detect(sql_norm, "\\bgroup\\s+by\\b"),
    Are_ORDER_BY = str_detect(sql_norm, "\\border\\s+by\\b"),
    Are_LIMIT = str_detect(sql_norm, "\\blimit\\b"),
    Are_DISTINCT = str_detect(sql_norm, "\\bdistinct\\b"),
    Are_HAVING = str_detect(sql_norm, "\\bhaving\\b"),
    Are_CASE = str_detect(sql_norm, "\\bcase\\b"),
    
    # Agregari
    Tipuri_Agregari = map_chr(sql_norm, extract_aggregations),
    Nr_Aparitii_Agregari = map_int(sql_norm, count_aggregation_occurrences),
    Are_Agregari = Nr_Aparitii_Agregari > 0,
    Nr_Tipuri_Agregari = if_else(
      Tipuri_Agregari == "",
      0L,
      str_count(Tipuri_Agregari, ",") + 1L
    ),
    
    # Predicate WHERE / HAVING
    where_text = map_chr(sql_norm, extract_clause_text, clause_name = "where"),
    having_text = map_chr(sql_norm, extract_clause_text, clause_name = "having"),
    
    Nr_Predicate_WHERE = map_int(where_text, count_operators),
    Operatori_WHERE = map_chr(where_text, extract_operators),
    
    Nr_Predicate_HAVING = map_int(having_text, count_operators),
    Operatori_HAVING = map_chr(having_text, extract_operators),
    
    # Operatii SQL avansate
    Are_Window = str_detect(sql_norm, "\\bover\\s*\\("),
    Are_UNION = str_detect(sql_norm, "\\bunion\\b"),
    Are_EXCEPT = str_detect(sql_norm, "\\bexcept\\b"),
    Are_INTERSECT = str_detect(sql_norm, "\\bintersect\\b"),
    Are_GROUPING = str_detect(sql_norm, "\\bgrouping\\s*\\("),
    Are_GROUPING_SETS = str_detect(sql_norm, "\\bgrouping\\s+sets\\b"),
    Are_ROLLUP = str_detect(sql_norm, "\\brollup\\s*\\("),
    Are_CUBE = str_detect(sql_norm, "\\bcube\\s*\\(")
  ) %>%
  select(
    ID_Interogare,
    
    Nr_Tabele,
    Nr_JOIN,
    Nr_Subquery,
    Nr_CTE,
    
    Nr_INNER_JOIN,
    Nr_LEFT_JOIN,
    Nr_RIGHT_JOIN,
    Nr_FULL_JOIN,
    Nr_CROSS_JOIN,
    
    Are_GROUP_BY,
    Are_ORDER_BY,
    Are_LIMIT,
    Are_DISTINCT,
    Are_HAVING,
    Are_CASE,
    
    Are_Agregari,
    Tipuri_Agregari,
    Nr_Tipuri_Agregari,
    Nr_Aparitii_Agregari,
    
    Nr_Predicate_WHERE,
    Operatori_WHERE,
    Nr_Predicate_HAVING,
    Operatori_HAVING,
    
    Are_Window,
    Are_UNION,
    Are_EXCEPT,
    Are_INTERSECT,
    Are_GROUPING,
    Are_GROUPING_SETS,
    Are_ROLLUP,
    Are_CUBE
  ) %>%
  arrange(ID_Interogare)

write_csv(
  query_metadata,
  file.path(output_dir, "query_metadata.csv")
)

# -----------------------------
# 6. Summary pentru tabelul cu elemente sintactice
# -----------------------------

join_types_observed <- c(
  if (sum(query_metadata$Nr_INNER_JOIN, na.rm = TRUE) > 0) "INNER JOIN",
  if (sum(query_metadata$Nr_LEFT_JOIN, na.rm = TRUE) > 0) "LEFT JOIN",
  if (sum(query_metadata$Nr_RIGHT_JOIN, na.rm = TRUE) > 0) "RIGHT JOIN",
  if (sum(query_metadata$Nr_FULL_JOIN, na.rm = TRUE) > 0) "FULL JOIN",
  if (sum(query_metadata$Nr_CROSS_JOIN, na.rm = TRUE) > 0) "CROSS JOIN"
)

clauses_observed <- c(
  if (any(query_metadata$Are_GROUP_BY)) "GROUP BY",
  if (any(query_metadata$Are_ORDER_BY)) "ORDER BY",
  if (any(query_metadata$Are_LIMIT)) "LIMIT",
  if (any(query_metadata$Are_DISTINCT)) "DISTINCT",
  if (any(query_metadata$Are_HAVING)) "HAVING",
  if (any(query_metadata$Are_CASE)) "CASE"
)

advanced_observed <- c(
  if (any(query_metadata$Are_Window)) "WINDOW/OVER",
  if (any(query_metadata$Are_UNION)) "UNION",
  if (any(query_metadata$Are_EXCEPT)) "EXCEPT",
  if (any(query_metadata$Are_INTERSECT)) "INTERSECT",
  if (any(query_metadata$Are_GROUPING)) "GROUPING",
  if (any(query_metadata$Are_GROUPING_SETS)) "GROUPING SETS",
  if (any(query_metadata$Are_ROLLUP)) "ROLLUP",
  if (any(query_metadata$Are_CUBE)) "CUBE"
)

summary_sql_elements <- tibble(
  Element_sintactic = c(
    "Numar de tabele",
    "Numar total de join-uri",
    "Tipuri de join",
    "Subinterogari",
    "Expresii tabela comune (CTE)",
    "Clauze SQL",
    "Functii de agregare",
    "Operatori in WHERE",
    "Operatori in HAVING",
    "Operatii SQL avansate"
  ),
  Valori = c(
    minmax_summary(query_metadata$Nr_Tabele),
    minmax_summary(query_metadata$Nr_JOIN),
    if_else(length(join_types_observed) == 0, "Nu au fost identificate", paste(join_types_observed, collapse = ", ")),
    minmax_summary(query_metadata$Nr_Subquery),
    minmax_summary(query_metadata$Nr_CTE),
    if_else(length(clauses_observed) == 0, "Nu au fost identificate", paste(clauses_observed, collapse = ", ")),
    collapse_unique_values(query_metadata$Tipuri_Agregari),
    collapse_unique_values(query_metadata$Operatori_WHERE),
    collapse_unique_values(query_metadata$Operatori_HAVING),
    if_else(length(advanced_observed) == 0, "Nu au fost identificate", paste(advanced_observed, collapse = ", "))
  )
)

write_csv(
  summary_sql_elements,
  file.path(output_dir, "summary_sql_elements.csv")
)

# -----------------------------
# 7. Summary pentru tabelul cu categorii sintactice
# -----------------------------

total_queries <- nrow(query_metadata)

summary_query_categories <- tibble(
  Categorie_sintactica = c(
    "Interogari cu agregari",
    "Interogari cu CTE",
    "Interogari cu subinterogari",
    "Interogari cu functii window",
    "Interogari cu operatori pentru multimi",
    "Interogari cu agregari avansate",
    "Interogari cu sortare explicita",
    "Interogari cu 0 join-uri",
    "Interogari cu 1 join",
    "Interogari cu 2 join-uri",
    "Interogari cu 3 join-uri",
    "Interogari cu 4 sau mai multe join-uri"
  ),
  Nr_Interogari = c(
    sum(query_metadata$Are_Agregari, na.rm = TRUE),
    sum(query_metadata$Nr_CTE > 0, na.rm = TRUE),
    sum(query_metadata$Nr_Subquery > 0, na.rm = TRUE),
    sum(query_metadata$Are_Window, na.rm = TRUE),
    sum(query_metadata$Are_UNION | query_metadata$Are_EXCEPT | query_metadata$Are_INTERSECT, na.rm = TRUE),
    sum(
      query_metadata$Are_GROUPING |
        query_metadata$Are_GROUPING_SETS |
        query_metadata$Are_ROLLUP |
        query_metadata$Are_CUBE,
      na.rm = TRUE
    ),
    sum(query_metadata$Are_ORDER_BY, na.rm = TRUE),
    sum(query_metadata$Nr_JOIN == 0, na.rm = TRUE),
    sum(query_metadata$Nr_JOIN == 1, na.rm = TRUE),
    sum(query_metadata$Nr_JOIN == 2, na.rm = TRUE),
    sum(query_metadata$Nr_JOIN == 3, na.rm = TRUE),
    sum(query_metadata$Nr_JOIN >= 4, na.rm = TRUE)
  )
) %>%
  mutate(
    Total_Interogari = total_queries,
    Pondere_pct = round(Nr_Interogari / Total_Interogari * 100, 2)
  ) %>%
  filter(Nr_Interogari > 0)

write_csv(
  summary_query_categories,
  file.path(output_dir, "summary_query_categories.csv")
)
