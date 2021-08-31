library(readxl)
library(tidyverse)
library("basedosdados")

# Indicador  Indicador Capital Poupado per capita (i413)

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
# PASSO 1: obter valor de depositos em poupanca e a prazo
# ------------------------------------------------------------------

# importar tabela com dados de operacoes de credito (dez. 2020)
# notar que a tabela e a mesma utilizada em i411
op_dep <- read.csv2('C:/Users/User/OneDrive/Documentos/ICE 2021/
                    d4 Acesso a Capital/sd41/i411/
                    202012_ESTBAN.csv', skip =2) %>%
  as_tibble() %>%
  transform(CODMUN = as.character(CODMUN)) %>%
  replace_na(list(VERBETE_420_DEPOSITOS_DE_POUPANCA = 0,
                  VERBETE_432_DEPOSITOS_A_PRAZO = 0)) %>%
  select(id_municipio_bcb = CODMUN,
         poup = VERBETE_420_DEPOSITOS_DE_POUPANCA,
         prazo = VERBETE_432_DEPOSITOS_A_PRAZO)

op_dep_ice <- op_dep %>%  
  inner_join(top100_mun_cod, by = 'id_municipio_bcb') %>%
  group_by(id_municipio, nome, sigla_uf) %>%
  summarise(soma_poup = sum(poup),
            soma_prazo = sum(prazo)) %>%
  mutate(poup_prazo = soma_poup + soma_prazo) %>%
  select(id_municipio, nome, sigla_uf, poup_prazo)

# ------------------------------------------------------------------
# PASSO 2: obter populacao estimada dos municipios
# ------------------------------------------------------------------

# obter estimativa populacionao de 2020
pop_ice <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/
                      estimativa_dou_2021.xls', sheet = 2, skip = 1) %>%
  na.omit() %>%
  select(nome = 'NOME DO MUNIC?PIO',
         sigla_uf = 'UF',
         populacao = 'POPULA??O ESTIMADA') %>%
  inner_join(top100_mun_cod, by = c('nome', 'sigla_uf')) %>%
  select(id_municipio, nome, sigla_uf, populacao)

# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

i413 <- pop_ice %>% 
  inner_join(op_dep_ice, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(i413 = poup_prazo/populacao,
         i413_pad = (i413 - mean(i413))/sdp(i413)) %>%
  select(id_municipio, nome, sigla_uf, i413, i413_pad) %>%
  arrange(desc(i413_pad))

# exportar indicador 
write.csv(i413, "i413.csv", row.names = FALSE)
