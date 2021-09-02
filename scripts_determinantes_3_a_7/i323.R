library(readxl)
library(tidyverse)
library("basedosdados")

# Indicador Compras Publicas (i323)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# definimos uma funcao para desvio padrao populacional para ser usada mais a frente no cÃ³digo
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio))

# Definir projeto no Google Cloud
set_billing_id("workshop-teste-322616")

# ------------------------------------------------------------------
# PASSO 1: obter despesas e investimentos das prefeituras
# ------------------------------------------------------------------

# importar planilha com dados de despesas orcamentarias dos municipios
despesas <- read.csv2('C:/Users/User/OneDrive/Documentos/ICE 2021/d3 Mercado/sd32/i323/finbra.csv', skip = 3)  
  
despesas_mun <- despesas %>% 
  select(id_municipio = 'Cod.IBGE',
         sigla_uf = UF,
         Conta,
         Valor) %>%
  filter(Conta == '3.0.00.00.00 - Despesas Correntes' | Conta == '4.4.00.00.00 - Investimentos') %>%
  group_by(id_municipio, sigla_uf) %>%
  summarise(desp_inv = sum(Valor)) %>%
  transform(id_municipio = as.character(id_municipio)) %>%
  inner_join(top100_mun_cod, by = c('id_municipio', 'sigla_uf')) %>%
  replace_na(list(desp_inv = 0))
  
# importar planilha com dados de brasilia
despesas_df <- read.csv2('C:/Users/User/OneDrive/Documentos/ICE 2021/d3 Mercado/sd32/i323/finbra-df.csv', skip = 3)  

despesas_df <- despesas_df %>% 
  select(id_estado = 'Cod.IBGE',
         sigla_uf = UF,
         Conta,
         Valor) %>%
  filter(Conta == '3.0.00.00.00 - Despesas Correntes' | Conta == '4.4.00.00.00 - Investimentos',
         sigla_uf == 'DF') %>%
  group_by(sigla_uf) %>%
  summarise(desp_inv = sum(Valor)) 

despesas_ice <- bind_rows(despesas_df, despesas_mun)
despesas_ice[1,3] = '5300108'
despesas_ice[1,4] = 'Bras�lia'

despesas_ice <- despesas_ice %>%
  right_join(top100_mun_cod, by = c('id_municipio', 'sigla_uf', 'nome')) %>%
  replace_na(list(desp_inv = 0)) %>%
  select(id_municipio, nome, sigla_uf, desp_inv) %>%
  arrange(desc(desp_inv))

# ------------------------------------------------------------------
# PASSO 2: obter numero de empresas com pelo menos 1 funcionario
# ------------------------------------------------------------------

# acessar RAIS estabelecimento pelo Base dos Dados para obter numero de empresas com pelo menos um funcionario em cada municipio
vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019", 
  page_size = 300000)

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

i323 <- despesas_ice %>%
  inner_join(temvinculo, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(i323 = desp_inv/n_empresas,
         i323_pad = (i323 - mean(i323))/sdp(i323)) %>%
  select(id_municipio, nome, sigla_uf, i323, i323_pad) %>%
  arrange(desc(i323_pad))
  
# exportar indicador
write.csv(i323, "i323.csv", row.names = FALSE)
