library(tidyverse)
library(readxl)

# indicadores do pedro ----------------------------------------------------
df_pedro <- list.files("dados_finais/", pattern = "^i\\d{3}.csv$") %>%
  paste0("dados_finais/", .)  %>%
  map( ~ read_csv(., locale = locale(encoding = "Latin1"))) %>% 
  reduce(full_join) %>%
  select(id_municipio, sigla_uf, nome, matches("^i\\d{3}$"))

# indicadores do douglas --------------------------------------------------
# lista os indicadores do douglas e monta o path para le-los
files_douglas <- list.files("dados_finais/", pattern = "sd") %>%
  paste0("dados_finais/",.) 

# le os indicadores e printa 'erro' ao inves de dar erro
ind_douglas <- files_douglas %>% 
  map(possibly(read_xlsx, otherwise = "erro"))

# agrupa os indicadores xlsx e seleciona as colunas relevantes
df_douglas_xlsx <- ind_douglas %>% 
  keep(is_tibble) %>% 
  reduce(bind_cols) %>%
  select(id_municipio = 1, sigla_uf = 2, nome = 3, matches("^i\\d{3}$"))

# onde deu erro
not_tibble <- which(!sapply(ind_douglas,is.tibble))

# onde deu erro mude a extensao para csv
files_douglas[not_tibble] <- 
  str_replace_all(files_douglas[not_tibble], ".xlsx",".csv")

# agrupa os indicadores csv e seleciona as colunas relevantes
df_douglas_csv <-  files_douglas[not_tibble] %>% 
  map(read_csv)%>% 
  reduce(bind_cols) %>%
  select(id_municipio = 1, sigla_uf = 2, nome = 3, matches("^i\\d{3}$"))



df_douglas <- bind_cols(df_douglas_csv,df_douglas_xlsx) %>%
  select(1,2, 3,matches("^i\\d{3}$")) %>%
  rename(id_municipio = 1, sigla_uf = 2, nome = 3)

# tudo junto --------------------------------------------------------------

df <- df_pedro %>%
  select(id_municipio, matches("^i\\d{3}$")) %>%
  left_join(df_douglas, by = "id_municipio", keep = FALSE)

indicadores <- names(df) %>% sort() %>% str_subset("^i\\d{3}$")

df_final <- df %>%
  select(id_municipio, sigla_uf, nome, all_of(indicadores))

df_final_indicadores <- df_final %>% 
  select(matches("^i\\d{3}$")) %>%
  mutate(across(everything(), as.numeric))

# testes ------------------------------------------------------------------

# testes indicadores douglas
df_douglas %>% map(is.na) %>%
  unlist() %>% sum()
# nenhum null
df_douglas %>% map(is.null) %>%
  unlist() %>% sum()
# nenhum Inf
df_douglas %>% map(is.infinite) %>%
  unlist() %>% sum()

# testes indicadores - geral
# nenhum NA
df_final_indicadores %>% map(is.na) %>%
  unlist() %>% sum()
# nenhum null
df_final_indicadores %>% map(is.null) %>%
  unlist() %>% sum()
# nenhum Inf
df_final_indicadores %>% map(is.infinite) %>%
  unlist() %>% sum()

# salva -------------------------------------------------------------------

write_csv(df_final,"pca/indicadores_completo.csv")

write_csv(df_final_indicadores,"pca/indicadores_pca.csv")

