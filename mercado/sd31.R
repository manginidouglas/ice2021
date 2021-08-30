library(tidyverse)
library(readxl)
library(basedosdados)
library(sidrar)
library(abjutils)

municode <- read_csv("municode.csv") %>%
  select(id_municipio, sigla_uf, nome) %>%
  mutate(id_municipio = as.character(id_municipio))

# idh ---------------------------------------------------------------------
idh <- read_excel("dados_finais/sd31_idh.xlsx", 
           col_names = c("id_municipio","nome","idh2010")) %>%
  right_join(municode) %>%
  select(id_municipio,sigla_uf,nome,idh2010)

write_excel_csv(idh,"dados_finais/sd31_idh.xlsx")


# crescimento medio real do pib -------------------------------------------
# pib nominal municipal

basedosdados::set_billing_id("ice2021")

pib_mun <- basedosdados::read_sql(
  query = "SELECT * 
  FROM `basedosdados.br_ibge_pib.municipio` 
  WHERE ano >= 2014 AND ano <= 2018") %>%
  select(1:3) %>% 
  pivot_wider(names_from = ano, values_from = pib, names_prefix = "pib_") %>%
  right_join(municode) %>%
  select(id_municipio,sigla_uf,nome, everything())

# pib_corrente e passado em milhoes de reais
d <- get_sidra(x = 6784, period = c("last" = 5),variable = c(9808,9809)) %>%
  as_tibble() %>%
  select(var = Variável, ano = Ano, valor = Valor) %>%
  pivot_wider(names_from = var, values_from = valor) %>%
  rename(ano = 1, pib_corrente = 2, pib_passado = 3) %>%
  rowwise() %>%
  mutate(relativo = pib_corrente/pib_passado) %>% 
  pull(relativo) 

d <-as.list(c(1, d[2], d[2]*d[3], d[2]*d[3]*d[4], d[2]*d[3]*d[4]*d[5])*100)
d
# deflacionar
names(d) <-pib_mun %>% select(where(is.numeric)) %>% names(.)

pib_mun_real <- pib_mun %>%
  mutate(across(all_of(names(d)), ~.x * 100/d[[cur_column()]]),
         var_1415 = (pib_2015/pib_2014)-1,
         var_1516 = (pib_2016/pib_2015)-1,
         var_1617 = (pib_2017/pib_2016)-1,
         var_1718 = (pib_2018/pib_2017)-1) %>%
  rowwise() %>%
  mutate(sd31_pib_var = mean(c_across(contains("var_")))) %>%
  arrange(-sd31_pib_var)

write_excel_csv(pib_mun_real, "dados_finais/sd31_pib_var.xlsx")

# exportadoras ------------------------------------------------------------

vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019", 
  page_size = 300000)
 
temvinculo <- vinculos %>% 
  filter(qtde_vinculos_ativos != 0) %>%
  group_by(id_municipio) %>%
  summarise(n_empresas = n()) %>%
  right_join(municode) %>%
  mutate(nome = nome %>% str_to_title() %>% rm_accent())

exportadoras <- read_excel("mercado/EMPRESAS_CADASTRO_2019.xlsx", skip = 7) %>%
  select(sigla_uf = UF, nome = MUNICÍPIO) %>%
  count(sigla_uf,nome, name = "n_exp") %>%
  mutate(nome = nome %>% str_to_title() %>% rm_accent())

df <- left_join(temvinculo,exportadoras) %>%
  select(id_municipio,sigla_uf,nome,n_empresas,n_exp) %>%
  mutate(exp_total = n_exp / n_empresas)

write_excel_csv(df,"dados_finais/sd31_exportadoras.xlsx")
