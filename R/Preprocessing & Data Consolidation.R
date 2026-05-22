# 0. Packages
library(tidyverse)
library(janitor)
library(scales)

# 1. Config

results_dir <- "C:/Users/savas/TCP-DS/citus_resuts_vm"
output_dir  <- "C:/Users/savas/TCP-DS/citus_outputs"


expected_queries <- tibble(
  query_no = 1:250,
  query_id = sprintf("Q%03d", query_no)
)

# 2. extragere metadate din numele fisierului

parse_file_metadata <- function(file_path) {
  file_name <- basename(file_path)
  file_no_ext <- str_remove(file_name, "\\.csv$")
  
  sf <- str_match(file_name, "sf(\\d+)")[, 2] %>% as.integer()
  
  workers <- case_when(
    str_detect(file_name, "baseline") ~ 0L,
    str_detect(file_name, "_n\\d+") ~ str_match(file_name, "_n(\\d+)")[, 2] %>% as.integer(),
    TRUE ~ NA_integer_
  )
  
  strategy <- case_when(
    str_detect(file_name, "baseline") ~ "baseline",
    str_detect(file_name, "_d1") ~ "D1",
    str_detect(file_name, "_d2") ~ "D2",
    TRUE ~ NA_character_
  )
  
  restart_from <- str_match(file_name, "_(\\d+)\\.csv$")[, 2] %>% as.integer()
  
  restart_from <- if_else(is.na(restart_from), 1L, restart_from)
  
  scenario <- if_else(
    strategy == "baseline",
    paste0("SF", sf, "_N0"),
    paste0("SF", sf, "_N", workers, "_", strategy)
  )
  
  tibble(
    source_file = file_name,
    sf = sf,
    workers = workers,
    strategy = strategy,
    scenario = scenario,
    restart_from = restart_from
  )
}

# 3. clasificare status query


classify_status <- function(success, response_code, response_message, elapsed_ms) {
  msg <- str_to_lower(coalesce(response_message, ""))
  code <- coalesce(response_code, "")
  
  case_when(
    success == TRUE ~ "SUCCESS",
    
    str_detect(msg, "canceling statement due to user request") |
      (elapsed_ms >= 3600000 & success == FALSE) ~ "TIMEOUT_3600",
    
    str_detect(msg, "an i/o error occurred while sending to the backend") |
      str_detect(msg, "server closed the connection") |
      str_detect(msg, "connection reset") |
      str_detect(msg, "terminating connection") |
      str_detect(code, "08006") ~ "SERVER_CRASH",
    
    str_detect(msg, "connection .* refused") |
      str_detect(msg, "connection refused") |
      str_detect(msg, "postmaster is accepting tcp/ip connections") |
      str_detect(code, "08001") ~ "POST_CRASH_CONNECTION_REFUSED",
    
    str_detect(msg, "complex joins are only supported") |
      str_detect(msg, "co-located and joined on their distribution columns") |
      str_detect(msg, "grouping sets") |
      str_detect(msg, "cube") |
      str_detect(msg, "rollup") |
      str_detect(msg, "multi_shard_modify_mode") |
      str_detect(msg, "cannot execute parallel ddl") |
      str_detect(msg, "subqueries in the select") |
      str_detect(msg, "recursive cte") |
      str_detect(msg, "could not run distributed query") |
      str_detect(msg, "not supported") |
      str_detect(msg, "unsupported") ~ "CITUS_ARCH_ERROR",
    
    TRUE ~ "OTHER_ERROR"
  )
}

classify_error_category <- function(status, response_message) {
  msg <- str_to_lower(coalesce(response_message, ""))
  
  case_when(
    status == "SUCCESS" ~ NA_character_,
    
    status == "TIMEOUT_3600" ~ "Timeout peste pragul de 3600 secunde",
    
    status == "SERVER_CRASH" ~ "Intrerupere conexiune / restart PostgreSQL necesar",
    
    status == "POST_CRASH_CONNECTION_REFUSED" ~ "Conexiune refuzata dupa oprirea serviciului",
    
    str_detect(msg, "complex joins are only supported") |
      str_detect(msg, "co-located and joined on their distribution columns") ~
      "Join complex intre tabele distribuite necolocate",
    
    str_detect(msg, "grouping sets") |
      str_detect(msg, "cube") |
      str_detect(msg, "rollup") ~
      "GROUPING SETS / CUBE / ROLLUP fara filtru pe cheia de distributie",
    
    str_detect(msg, "multi_shard_modify_mode") |
      str_detect(msg, "cannot execute parallel ddl") ~
      "Parallel DDL + FK catre reference table",
    
    str_detect(msg, "subqueries in the select") ~
      "Subquery in lista SELECT nepusa in push-down",
    
    str_detect(msg, "recursive cte") ~
      "Recursive CTE neexecutabil distribuit in forma curenta",
    
    status == "CITUS_ARCH_ERROR" ~ "Alta limitare arhitecturala Citus",
    
    status == "OTHER_ERROR" ~ "Alta eroare",
    
    TRUE ~ NA_character_
  )
}

# 4. Import CSV-urile

csv_files <- list.files(
  path = results_dir,
  pattern = "^rezultate_.*\\.csv$",
  full.names = TRUE
)
raw_results <- map_dfr(csv_files, function(file_path) {
  meta <- parse_file_metadata(file_path)
  
  read_csv(
    file_path,
    col_types = cols(.default = col_character()),
    show_col_types = FALSE
  ) %>%
    clean_names() %>%
    mutate(
      source_file = meta$source_file,
      sf = meta$sf,
      workers = meta$workers,
      strategy = meta$strategy,
      scenario = meta$scenario,
      restart_from = meta$restart_from
    )
})

# 5. Curatare coloane JMeter

raw_results_clean <- raw_results %>%
  mutate(
    query_no = parse_number(label),
    query_id = sprintf("Q%03d", query_no),
    
    elapsed_ms = as.numeric(elapsed),
    elapsed_sec = elapsed_ms / 1000,
    
    success_logical = case_when(
      str_to_lower(success) == "true" ~ TRUE,
      str_to_lower(success) == "false" ~ FALSE,
      TRUE ~ NA
    ),
    
    response_code = response_code,
    response_message = response_message,
    
    status_raw = classify_status(
      success = success_logical,
      response_code = response_code,
      response_message = response_message,
      elapsed_ms = elapsed_ms
    ),
    
    error_category_raw = classify_error_category(
      status = status_raw,
      response_message = response_message
    )
  ) %>%
  filter(!is.na(query_no)) %>%
  filter(query_no >= restart_from)

# 6. Consolidare reluari (_102, _184, _185 etc.)
# - fisierul initial are restart_from = 1
# - fisierul _102 are restart_from = 102
# - pentru acelasi scenariu + query_id, se pastreaza randul din reluarea cea mai tarzie
# - astfel, Q102-Q250 din fisierul initial sunt inlocuite de Q102-Q250 din fisierul _102

results_master <- raw_results_clean %>%
  arrange(scenario, query_no, desc(restart_from)) %>%
  group_by(scenario, query_id) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(
    status = case_when(
      status_raw == "POST_CRASH_CONNECTION_REFUSED" ~ "POST_CRASH_CONNECTION_REFUSED",
      TRUE ~ status_raw
    ),
    error_category = error_category_raw
  ) %>%
  select(
    scenario, sf, workers, strategy,
    query_no, query_id,
    status, error_category,
    elapsed_ms, elapsed_sec,
    success = success_logical,
    response_code, response_message,
    source_file, restart_from
  ) %>%
  arrange(sf, workers, strategy, query_no)

# 7. Completare query-urile lipsa, daca exista

scenarios <- results_master %>%
  distinct(scenario, sf, workers, strategy)

results_master_complete <- scenarios %>%
  crossing(expected_queries) %>%
  left_join(
    results_master,
    by = c("scenario", "sf", "workers", "strategy", "query_no", "query_id")
  ) %>%
  mutate(
    status = replace_na(status, "MISSING_NOT_EXECUTED"),
    success = replace_na(success, FALSE),
    error_category = case_when(
      status == "MISSING_NOT_EXECUTED" ~ "Lipsa rezultat in fisierele JMeter",
      TRUE ~ error_category
    )
  ) %>%
  arrange(sf, workers, strategy, query_no)
# 8. Export dataset principal

write_csv(
  results_master_complete,
  file.path(output_dir, "results_master.csv")
)
