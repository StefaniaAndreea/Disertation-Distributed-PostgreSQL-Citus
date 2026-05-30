# ============================================================
# Query Metadata Extraction.R# ============================================================
# V2 corrected naming
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
# 2. Lista tabele TPC-DS folosite pentru n_tables
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
    query_id = id_interogare,
    sql_norm = normalize_sql(sql_inline)
  ) %>%
  mutate(
    # Complexitate generala
    n_tables = map_int(sql_norm, count_tpcds_tables),
    n_joins = str_count(sql_norm, "\\bjoin\\b"),
    
    # Tipuri JOIN
    n_left_joins  = str_count(sql_norm, "\\bleft\\s+(outer\\s+)?join\\b"),
    n_right_joins = str_count(sql_norm, "\\bright\\s+(outer\\s+)?join\\b"),
    n_full_joins  = str_count(sql_norm, "\\bfull\\s+(outer\\s+)?join\\b"),
    n_cross_joins = str_count(sql_norm, "\\bcross\\s+join\\b"),
    
    n_inner_joins = pmax(
      0L,
      n_joins - n_left_joins - n_right_joins - n_full_joins - n_cross_joins
    ),
    
    n_ctes = map_int(sql_norm, count_cte_defs),
    n_subqueries = map2_int(sql_norm, n_ctes, count_subqueries),
    
    # Clauze SQL
    has_group_by = str_detect(sql_norm, "\\bgroup\\s+by\\b"),
    has_order_by = str_detect(sql_norm, "\\border\\s+by\\b"),
    has_limit = str_detect(sql_norm, "\\blimit\\b"),
    has_distinct = str_detect(sql_norm, "\\bdistinct\\b"),
    has_having = str_detect(sql_norm, "\\bhaving\\b"),
    has_case = str_detect(sql_norm, "\\bcase\\b"),
    
    # Agregari
    aggregate_types = map_chr(sql_norm, extract_aggregations),
    n_aggregate_calls = map_int(sql_norm, count_aggregation_occurrences),
    has_aggregates = n_aggregate_calls > 0,
    n_aggregate_types = if_else(
      aggregate_types == "",
      0L,
      str_count(aggregate_types, ",") + 1L
    ),
    
    # Predicate WHERE / HAVING
    where_text = map_chr(sql_norm, extract_clause_text, clause_name = "where"),
    having_text = map_chr(sql_norm, extract_clause_text, clause_name = "having"),
    
    n_where_predicates = map_int(where_text, count_operators),
    where_operators = map_chr(where_text, extract_operators),
    
    n_having_predicates = map_int(having_text, count_operators),
    having_operators = map_chr(having_text, extract_operators),
    
    # Operatii SQL avansate
    has_window = str_detect(sql_norm, "\\bover\\s*\\("),
    has_union = str_detect(sql_norm, "\\bunion\\b"),
    has_except = str_detect(sql_norm, "\\bexcept\\b"),
    has_intersect = str_detect(sql_norm, "\\bintersect\\b"),
    has_grouping = str_detect(sql_norm, "\\bgrouping\\s*\\("),
    has_rollup = str_detect(sql_norm, "\\brollup\\s*\\("),
    has_cube = str_detect(sql_norm, "\\bcube\\s*\\(")
  ) %>%
  select(
    query_id,
    
    n_tables,
    n_joins,
    n_subqueries,
    n_ctes,
    
    n_inner_joins,
    n_left_joins,
    n_right_joins,
    n_full_joins,
    n_cross_joins,
    
    has_group_by,
    has_order_by,
    has_limit,
    has_distinct,
    has_having,
    has_case,
    
    has_aggregates,
    aggregate_types,
    n_aggregate_types,
    n_aggregate_calls,
    
    n_where_predicates,
    where_operators,
    n_having_predicates,
    having_operators,
    
    has_window,
    has_union,
    has_except,
    has_intersect,
    has_grouping,
    has_rollup,
    has_cube
  ) %>%
  arrange(query_id)
 
write_csv(
  query_metadata,
  file.path(output_dir, "query_metadata.csv")
)
 
# -----------------------------
# 6. Summary pentru tabelul cu elemente sintactice
# -----------------------------
 
join_types_observed <- c(
  if (sum(query_metadata$n_inner_joins, na.rm = TRUE) > 0) "INNER JOIN",
  if (sum(query_metadata$n_left_joins, na.rm = TRUE) > 0) "LEFT JOIN",
  if (sum(query_metadata$n_right_joins, na.rm = TRUE) > 0) "RIGHT JOIN",
  if (sum(query_metadata$n_full_joins, na.rm = TRUE) > 0) "FULL JOIN",
  if (sum(query_metadata$n_cross_joins, na.rm = TRUE) > 0) "CROSS JOIN"
)
 
clauses_observed <- c(
  if (any(query_metadata$has_group_by)) "GROUP BY",
  if (any(query_metadata$has_order_by)) "ORDER BY",
  if (any(query_metadata$has_limit)) "LIMIT",
  if (any(query_metadata$has_distinct)) "DISTINCT",
  if (any(query_metadata$has_having)) "HAVING",
  if (any(query_metadata$has_case)) "CASE"
)
 
advanced_observed <- c(
  if (any(query_metadata$has_window)) "WINDOW/OVER",
  if (any(query_metadata$has_union)) "UNION",
  if (any(query_metadata$has_except)) "EXCEPT",
  if (any(query_metadata$has_intersect)) "INTERSECT",
  if (any(query_metadata$has_grouping)) "GROUPING",
  if (any(query_metadata$has_rollup)) "ROLLUP",
  if (any(query_metadata$has_cube)) "CUBE"
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
    minmax_summary(query_metadata$n_tables),
    minmax_summary(query_metadata$n_joins),
    if_else(length(join_types_observed) == 0, "Nu au fost identificate", paste(join_types_observed, collapse = ", ")),
    minmax_summary(query_metadata$n_subqueries),
    minmax_summary(query_metadata$n_ctes),
    if_else(length(clauses_observed) == 0, "Nu au fost identificate", paste(clauses_observed, collapse = ", ")),
    collapse_unique_values(query_metadata$aggregate_types),
    collapse_unique_values(query_metadata$where_operators),
    collapse_unique_values(query_metadata$having_operators),
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
    sum(query_metadata$has_aggregates, na.rm = TRUE),
    sum(query_metadata$n_ctes > 0, na.rm = TRUE),
    sum(query_metadata$n_subqueries > 0, na.rm = TRUE),
    sum(query_metadata$has_window, na.rm = TRUE),
    sum(query_metadata$has_union | query_metadata$has_except | query_metadata$has_intersect, na.rm = TRUE),
    sum(
      query_metadata$has_grouping |
        query_metadata$has_rollup |
        query_metadata$has_cube,
      na.rm = TRUE
    ),
    sum(query_metadata$has_order_by, na.rm = TRUE),
    sum(query_metadata$n_joins == 0, na.rm = TRUE),
    sum(query_metadata$n_joins == 1, na.rm = TRUE),
    sum(query_metadata$n_joins == 2, na.rm = TRUE),
    sum(query_metadata$n_joins == 3, na.rm = TRUE),
    sum(query_metadata$n_joins >= 4, na.rm = TRUE)
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