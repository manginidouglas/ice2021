library(readxl)
library(tidyverse)
library("basedosdados")

# Indicador Operacoes de Credito por Municipio (i411)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# definimos uma funcao para desvio padrao populacional
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# Definir projeto no Google Cloud
set_billing_id("workshop-teste-322616")

# obter codigos de municipio do banco central
query <- "SELECT * FROM `basedosdados.br_bd_diretorios_brasil.municipio`"
cod_mun <- read_sql(query) %>% select(id_municipio, id_municipio_bcb)

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio)) %>%
  inner_join(cod_mun, by = "id_municipio")

# ------------------------------------------------------------------
# PASSO 1: obter valor em reais das operacoes de credito
# ------------------------------------------------------------------

# importar tabela com dados de operacoes de credito (dez. 2020) 
op_cred <- read.csv2('C:/Users/User/OneDrive/Documentos/ICE 2021/
                     d4 Acesso a Capital/sd41/
                     i411/202012_ESTBAN.csv', skip =2) %>%
  as_tibble() %>%
  transform(CODMUN = as.character(CODMUN)) %>%
  replace_na(list(VERBETE_160_OPERACOES_DE_CREDITO = 0)) %>%
  select(id_municipio_bcb = CODMUN,
         op_cred = VERBETE_160_OPERACOES_DE_CREDITO)

op_cred_ice <- op_cred %>%  
  inner_join(top100_mun_cod, by = 'id_municipio_bcb') %>%
  group_by(id_municipio, nome, sigla_uf) %>%
  summarise(valor_total = sum(op_cred))
  
# ------------------------------------------------------------------
# PASSO 2: obter PIB dos municipios
# ------------------------------------------------------------------

# importar tabela com PIB a nivel de municipios
# os nomes das colunas foram previamente alterados no excel
pib <- read.csv2('C:/Users/User/OneDrive/Documentos/ICE 2021/
                 d4 Acesso a Capital/sd41/i411/tabela5938.csv', skip = 3)

pib_ice <- pib %>% 
  inner_join(top100_mun_cod, by = 'id_municipio') %>%
  mutate(pib = pib_milreais * 1000) %>%
  select(id_municipio, nome = nome.y, sigla_uf, pib)

# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

i411 <- pib_ice %>% 
  inner_join(op_cred_ice, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(i411 = valor_total/pib,
         i411_pad = (i411 - mean(i411))/sdp(i411)) %>%
  select(id_municipio, nome, sigla_uf, i411, i411_pad) %>%
  arrange(desc(i411_pad))

# exportar indicador 
write.csv(i411, "i411.csv", row.names = FALSE)

                               