library(tidyverse)
library("basedosdados")
library(readxl)

# Indicador Nota do Ideb (i611)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

#definimos uma funcao para desvio padrao populacional
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio))

top100_mun_cod$NOME <- toupper(top100_mun_cod$nome)

# ------------------------------------------------------------------
# PASSO 1: obter notas ideb 2019
# ------------------------------------------------------------------

#importamos a base de dados necessaria para calcular o indicador
ideb <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd61 Acesso e Qualidade da Mão de Obra Básica/i611 base de dados.xlsx", range = "A2:J5570")
ideb_2019 <- ideb %>% select((1:2), '2019') %>% 
  rename(sigla_uf = UF, 
         Ideb_2019 = "2019",
         NOME = 'Município')

# juntar com tabela dos municipios mais populosos
ideb_100mun <- top100_mun_cod %>% 
  left_join(ideb_2019, by = c("NOME", "sigla_uf")) %>% 
  select(-NOME)

# ------------------------------------------------------------------
# PASSO 2: calcular indicador e padroniza-lo
# ------------------------------------------------------------------

i611 <- ideb_100mun %>% 
  rename(i611 = Ideb_2019) %>% 
  transform(i611 = as.numeric(i611), 
            id_municipio = as.character(id_municipio)) %>% 
  mutate(i611_pad = (i611 - mean(i611))/sdp(i611))

# exportar tabela com indicador
write.csv(i611, "i611.csv", row.names = FALSE)
