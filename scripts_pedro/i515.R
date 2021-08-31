library(readxl)
library(tidyverse)

# Indicador Contratos de Concessao (i515)

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
  transform(id_municipio = as.numeric(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: importar indicador do ano passado e padronizar
# ------------------------------------------------------------------

i515 <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd51 Inputs/i515/Indicador Contratos de Concessão.xlsx", sheet = "Indicador") %>%
        rename(nome = Cidade,
               id_municipio = Código,
               i515 = Indicador) %>%
        mutate(i515_pad = (i515 - (mean(i515)))/sdp(i515)) %>%
        inner_join(top100_mun_cod, by = c('id_municipio', 'nome')) %>%
        select(id_municipio, nome, sigla_uf, i515, i515_pad) %>%
        arrange(desc(i515_pad))

# ------------------------------------------------------------------
# PASSO 2: exportar indicador 
# ------------------------------------------------------------------

# salvamos o arquivo com o indicador
write.csv(i515, "i515.csv", row.names = FALSE) 
