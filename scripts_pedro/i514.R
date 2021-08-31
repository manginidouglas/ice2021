library(readxl)
library(tidyverse)

# Indicador Infraestrutura Tecnologica (i514)

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
# PASSO 1 e 2: obter planilha com dados do indicador e padronizar
# ------------------------------------------------------------------

i514 <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd51 Inputs/i514/Indicador Infraestrutura Tecnológica.xlsx", sheet = 2) %>%
        inner_join(top100_mun_cod, by = c('Cidade' = 'nome')) %>%
        rename(i514 = Indicador, nome = Cidade) %>%
        mutate(i514_pad = (i514 - mean(i514))/sdp(i514)) %>%
        select(id_municipio, nome, sigla_uf, i514, i514_pad) 
  
# salvamos o arquivo com o indicador
write.csv(i514, "i514.csv", row.names = FALSE) 
