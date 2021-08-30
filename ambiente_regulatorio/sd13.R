# simplicidade tributaria -------------------------------------------------

library(tidyverse)
library(readxl)
library(pdftools)
# maiores municipios
municode <- read_csv("municode.csv") %>% select(id_municipio,sigla_uf,nome)

# conta das receitas para calcular os indices 
contas_interessantes <- pdf_text(
  "ambiente_regulatorio/pdf_contas.pdf") %>% 
  str_split("\n") %>% 
  unlist() %>% 
  str_extract_all("(\\d\\.){4}(\\d){2}(\\.\\d){2}") %>%
  unlist()

# receitas dos municipios 
df <- read.delim("ambiente_regulatorio/dados/finbramun.csv",
                        dec = ",", sep = ";", skip = 3) 

df_sep <- df %>%
  separate(Conta, c("conta_num","descricao"), sep = " ",extra = "merge") 

finbramun <- df_sep %>%
  select(id_municipio = Cod.IBGE, coluna = Coluna, conta = Conta, 
         valor = Valor) %>%
  filter(id_municipio %in% municode$id_municipio, 
         coluna == "Receitas Brutas Realizadas") %>% 
  select(-coluna) %>% 
  as_tibble() %>%
  separate(conta, c("conta_num","descricao"), sep = " ",extra = "merge") %>%
  filter(conta_num %>% str_detect("(\\d\\.){4}(\\d){2}(\\.\\d){2}"))

# HH index
ihh <- finbramun %>% 
  group_by(id_municipio) %>%
  mutate(receita_total = sum(valor, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(conta_num %in% contas_interessantes[1:52]) %>%
  group_by(id_municipio,conta_num) %>%
  summarise(conta_total_quad = (valor/receita_total)^2) %>%
  group_by(id_municipio) %>%
  summarise(ihh = sum(conta_total_quad))

# iv index
iv <- finbramun %>% 
  group_by(id_municipio) %>%
  mutate(receita_total = sum(valor)) %>%
  ungroup() %>%
  filter(conta_num %in% contas_interessantes[53:56]) %>%
  group_by(id_municipio, receita_total) %>%
  summarise(conta_total = sum(valor)) %>%
  mutate(iv = conta_total/receita_total) %>%
  select(id_municipio,iv)

# tem um 'municipio' faltando: brasilia
municode %>% 
  filter(
    id_municipio == setdiff(municode$id_municipio,finbramun$id_municipio))

#tudo junto
df <- left_join(ihh,iv) %>%
  mutate(sd13_complexidade = ihh * iv) %>%
  left_join(municode) %>%
  select(id_municipio,sigla_uf,nome,everything()) %>%
  arrange(-sd13_complexidade) %>%
  add_row(id_municipio = 5300108, nome = "Brasília", ihh = 0, iv = 0, 
          sd13_complexidade = 0)

# salvar 
write_excel_csv(df, "dados_finais/sd13_simplicidade_tributaria.xlsx")

# CND ---------------------------------------------------------------------

sd13_cnd <- read_excel(
  "ambiente_regulatorio/dados/Base_MUNIC_2019_20210817.xlsx",
                       sheet = 4) %>%
  select(id_municipio = 1, tem_cnd = MTIC1211) %>%
  mutate(tem_cnd = if_else(tem_cnd == "Sim",1,0)) %>%
  right_join(municode, keep = FALSE) %>%
  select(id_municipio,sigla_uf,nome, sd13_cnd = tem_cnd)

write_excel_csv(sd13_cnd,"dados_finais/sd13_cnd.xlsx")

# atualizacao de zoneamento -----------------------------------------------

municode <- read_csv("municode.csv") %>%
  select(id_municipio,sigla_uf, nome)

sd13_zone <- read_excel(
  "ambiente_regulatorio/dados/Base_MUNIC_2018_xlsx_20201103.xlsx",
                        sheet = 3, na = "-") %>%
  select(id_municipio = 1, update_zone = MLEG061) %>%
  mutate(dif = if_else(is.na(update_zone),Inf, 2019 - as.double(update_zone)),
         indice = 1/dif) %>%
  right_join(municode,keep = FALSE) %>%
  select(id_municipio, sigla_uf,nome,update_zone,dif,indice)

write_excel_csv(sd13_zone, "dados_finais/sd13_zone.xlsx")  


