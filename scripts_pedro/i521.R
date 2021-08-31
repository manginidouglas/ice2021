library(readxl)
library(tidyverse)
library("basedosdados")

#  Indicador Patentes (i521)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# Definir projeto no Google Cloud
set_billing_id("workshop-teste-322616")

# definimos uma funcao para desvio padrao populacional 
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.numeric(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: obter dados de depositos de patentes
# ------------------------------------------------------------------

# importar planilhas com dados de depositos de patentes
# observacao: nesta planilha, foram feitas pequenas alteracoes em celulas mescladas
patentes_pi <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd52 Outputs/i521/5a - Depósitos de Patentes do Tipo PI por Cidade.xls', skip = 7) %>% 
  na.omit() %>% 
  rename(ano2018 = '2018', ano2019 = '2019', id_municipio = 'Cod IBGE', nome = 'Cidade') %>%
  mutate(pat_pi = ano2018 + ano2019) %>%
  select(id_municipio, nome, pat_pi)

patentes_mu <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd52 Outputs/i521/5b - Depósitos de Patentes do Tipo MU por Cidade.xls', skip = 7) %>% 
  na.omit() %>% 
  rename(ano2018 = '2018', ano2019 = '2019', id_municipio = 'Cod IBGE', nome = 'Cidade') %>%
  mutate(pat_mu = ano2018 + ano2019) %>%
  select(id_municipio, nome, pat_mu)

patentes_ca <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd52 Outputs/i521/5c - Depósitos de Patentes do Tipo CA por Cidade.xls', skip = 7) %>% 
  na.omit() %>% 
  rename(ano2018 = '2018', ano2019 = '2019', id_municipio = 'Cod IBGE', nome = 'Cidade') %>%
  mutate(pat_ca = ano2018 + ano2019) %>%
  select(id_municipio, nome, pat_ca) %>%
  transform(id_municipio = as.numeric(id_municipio))

# juntar as tres tabelas
patentes <- patentes_pi %>%
  full_join(patentes_mu, by = c('id_municipio', 'nome')) %>%
  full_join(patentes_ca, by = c('id_municipio', 'nome')) %>%
  replace_na(list(pat_pi = 0,
                  pat_mu = 0,
                  pat_ca = 0)) %>%
  mutate(pat = pat_pi + pat_mu + pat_ca) %>%
  select(id_municipio, nome, pat)

# ------------------------------------------------------------------
# PASSO 2: obter numero de empresas com pelo menos 1 funcionario
# ------------------------------------------------------------------

# acessar RAIS estabelecimento pelo Base dos Dados para obter numero de empresas com pelo menos um funcionario em cada municipio
vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019", 
  page_size = 300000)

top100_mun_cod$id_municipio = as.character(top100_mun_cod$id_municipio)

temvinculo <- vinculos %>% 
  filter(qtde_vinculos_ativos != 0) %>%
  group_by(id_municipio) %>%
  summarise(n_empresas = n()) %>%
  right_join(top100_mun_cod, by = "id_municipio") %>%
  select(id_municipio, nome, sigla_uf,n_empresas) %>%
  arrange(desc(n_empresas))

# ------------------------------------------------------------------
# PASSO 3: juntar tabelas e calcular indicador
# ------------------------------------------------------------------

i521 <- temvinculo %>% 
  transform(id_municipio = as.numeric(id_municipio)) %>%
  left_join(patentes, by = c('id_municipio', 'nome')) %>%
  mutate(i521 = pat/n_empresas,
         i521_pad = (i521 - mean(i521))/sdp(i521)) %>%
  select(id_municipio, nome, sigla_uf, i521, i521_pad) %>%
  arrange(desc(i521_pad))

# exportar indicador
write.csv(i521, "i521.csv", row.names = FALSE) 
