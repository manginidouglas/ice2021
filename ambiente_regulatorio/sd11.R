library(tidyverse)
library(readxl)
library(abjutils)
library(janitor)

# maiores municipios
municode <- read_csv("municode.csv") %>% 
  select(id_municipio,sigla_uf, nome) %>%
  mutate(nome = abjutils::rm_accent(nome) %>% str_to_title())

# pega colunas que interessam para os indicadores de endereco e nome
col_interesse <- read_excel(
  "ambiente_regulatorio/dados/sd11_localiza_nome/sd11abr20.xlsx", 
                        sheet = 1, 
                        skip = 1) %>%
  names() %>%
  str_subset(pattern = "QTDE") 
  
col_interesse <-col_interesse[c(1,2,5,7)]

# Le os dados de abertura
aberturas <- list.files("ambiente_regulatorio/dados/sd11_localiza_nome/") %>%
  paste0("ambiente_regulatorio/dados/sd11_localiza_nome/",.) %>%
  map_dfr(~read_excel(.,sheet = 1, skip = 1)) 
# limpa os dados
aberturas_clean <- aberturas %>%
  select(sigla_uf = UF, nome = MUNICÍPIO,all_of(col_interesse)) %>%
  janitor::clean_names() %>%
  mutate(nome = str_to_title(nome))

# filtra os maiores municipios 
aberturas_top <- aberturas_clean %>%
  right_join(municode)

# Tempo Viabilidade Localizacao -------------------------------------------
tempo_localiza<- aberturas_top %>%
  filter(!is.na(qtde_hh_viabilidade_end)) %>%
  group_by(id_municipio,sigla_uf,nome) %>%
  summarise(tempo_medio = mean(qtde_hh_viabilidade_end,na.rm = TRUE),
            sd11_localiza = 1/tempo_medio)

# encontra cidades faltantes  
id_faltantes <- setdiff(municode$id_municipio,tempo_localiza$id_municipio)

faltantes <- municode %>%
  filter(id_municipio %in% id_faltantes) %>%
  select(id_municipio,sigla_uf,nome)
  
# completa com 0 as faltantes
tempo_localiza <- tempo_localiza %>%
  ungroup() %>%
  add_row(id_municipio = as.double(faltantes$id_municipio),
          sigla_uf = faltantes$sigla_uf,
          nome = faltantes$nome,
          tempo_medio = 0,
          sd11_localiza = 0) %>%
  arrange(-sd11_localiza)

# Tempo Viabilidade Nome --------------------------------------------------
cols_sd11_nome <- c("nome","dbe","deferimento")

tempo_nome <- aberturas_clean %>% 
  select(sigla_uf,nome,contains(cols_sd11_nome)) %>% 
  group_by(sigla_uf) %>%
  summarise(across(contains("qtde"), ~sum(.x, na.rm = TRUE)),
            ordens = n()) %>%
  rowwise(sigla_uf) %>% 
  mutate(tempo_sum =sum(c_across(contains("qtde"))),
    tempo_nome_medio = tempo_sum/ordens,
    sd11_nome = 1/tempo_nome_medio)

# monta numa planilha os indicadores endereco e nome
sd11_localiza_nome <- tempo_nome %>%
  select(sigla_uf, sd11_nome) %>%
  right_join(tempo_localiza) %>%
  select(id_municipio,sigla_uf,nome,sd11_localiza, sd11_nome)

# salva o arquivo
write_excel_csv(sd11_localiza_nome, "dados_finais/sd11_localiza_nome.xlsx")

# congestionamento em tribunais -------------------------------------------
# processos 
novos <- read_excel(
  "ambiente_regulatorio/dados/sd11_processos_novos.xlsx")
baixados <- read_excel(
  "ambiente_regulatorio/dados/sd11_processos_baixados.xlsx")
pendentes <- read_excel(
  "ambiente_regulatorio/dados/sd11_processos_pendentes.xlsx")


sd11_congestionamento_tribunais <- 
  list.files("ambiente_regulatorio/dados/", pattern = "sd11_processos_") %>%
  paste0("ambiente_regulatorio/dados/",.) %>%
  map(~read_excel(., col_names = c("nome",.), skip = 1)) %>%
  reduce(full_join) %>%
  rename(nome = nome, baixados = 2, novos = 3, pendentes = 4) %>%
  mutate(nome = nome %>% str_to_title() %>% abjutils::rm_accent()) %>%
  right_join(municode) %>%
  mutate(congest = 1 - (baixados/(novos+pendentes)),
         sd11_congestionamento = 1/congest) %>%
  select(id_municipio,sigla_uf,nome,everything()) %>%
  arrange(-sd11_congestionamento)


write_excel_csv(sd11_congestionamento_tribunais,
                "dados_finais/sd11_congestionamento_tribunais.xlsx")  
