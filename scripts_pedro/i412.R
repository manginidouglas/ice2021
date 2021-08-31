library(readxl)
library(tidyverse)

# Indicador Proporcao Relativa de Capital de Risco (i412)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# definimos uma funcao para desvio padrao populacional
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: obter capital de risco por municipio no ultimo ano
# ------------------------------------------------------------------

# importar tabela construida manualmente a partir do site crunchbase
# taxa media de cambio do ultimo ano: 5.360819 para dolar e 6.408495 para euro
caprisco <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/
                       d4 Acesso a Capital/sd41/i412/caprisco.xlsx', sheet = 2)

caprisco_dolar <- caprisco %>% 
  filter(dolar ==1) %>%
  mutate(valor = valor*5.360819) %>%
  select(nome, sigla_uf, empresa, valor)

caprisco_real <- caprisco %>% 
  filter(real ==1) %>%
  select(nome, sigla_uf, empresa, valor)

caprisco_euro <- caprisco %>% 
  filter(euro ==1) %>%
  mutate(valor = valor*6.408495) %>%
  select(nome, sigla_uf, empresa, valor)

caprisco_ice <- rbind(caprisco_real, caprisco_dolar, caprisco_euro) %>%
  group_by(nome, sigla_uf) %>%
  summarise(valor_total = sum(valor)) %>%
  right_join(top100_mun_cod, by = c('nome', 'sigla_uf')) %>%
  replace_na(list(valor_total = 0)) %>%
  select(id_municipio, nome, sigla_uf, valor_total)

# ------------------------------------------------------------------
# PASSO 1: padronizar indicador
# ------------------------------------------------------------------

i412 <- caprisco_ice %>%
  transform(valor_total = as.numeric(valor_total)) %>%
  mutate(i412 = valor_total,
         i412_pad = (i412 - mean(i412))/sdp(i412)) %>%
  select(id_municipio, nome, sigla_uf, i412, i412_pad) %>%
  arrange(desc(i412_pad))

# exportar indicador
write.csv(i412, "i412.csv", row.names = FALSE)
