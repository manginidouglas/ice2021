library(tidyverse)

# Indicadores do Determinante Cultura

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

#definimos uma funcao para desvio padrão amostral para ser usada mais a frente no código
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.numeric(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: importar dados sobre pesquisas as palavras-chave
# ------------------------------------------------------------------

# importar arquivos referentes ao subdeterminante iniciativa (sd71)
termo_empreendedor <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/empreendedor.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")
termo_mei <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/mei.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")

# importar arquivos referentes ao subdeterminante instituicoes (sd72)
termo_sebrae <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/sebrae.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")
termo_franquia <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/franquia.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")
termo_simplesnacional <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/simples nacional.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")
termo_senac <- read.csv("C:/Users/User/OneDrive/Documentos/ICE 2021/d7 Determinante Cultura/senac.csv", stringsAsFactors = FALSE, header = 1, skip =2, fileEncoding = "UTF-8")


# calcular indicador pesquisas com o termo 'empreendedor'
i711 <- top100_mun_cod %>% left_join(termo_empreendedor, by = c("nome" = "City")) %>% 
  replace_na(list(empreendedor...2020. = 0)) %>%
  rename(i711 = empreendedor...2020.) %>%
  mutate(i711_pad = (i711 - mean(i711))/sdp(i711)) %>%
  arrange(desc(i711_pad))

# calcular indicador pesquisas com o termo 'mei'
i712 <- top100_mun_cod %>% left_join(termo_mei, by = c("nome" = "City")) %>% 
  replace_na(list(MEI...2020. = 0)) %>%
  rename(i712 = MEI...2020.) %>%
  mutate(i712_pad = (i712 - mean(i712))/sdp(i712)) %>%
  arrange(desc(i712_pad))

# calcular indicador pesquisas com o termo 'sebrae'
i721 <- top100_mun_cod %>% left_join(termo_sebrae, by = c("nome" = "City")) %>% 
  replace_na(list(Sebrae...2020. = 0)) %>%
  rename(i721 = Sebrae...2020.) %>%
  mutate(i721_pad = (i721 - mean(i721))/sdp(i721)) %>%
  arrange(desc(i721_pad))

# calcular indicador pesquisas com o termo 'franquia'
i722 <- top100_mun_cod %>% left_join(termo_franquia, by = c("nome" = "City")) %>% 
  replace_na(list(Franquia...2020. = 0)) %>%
  rename(i722 = Franquia...2020.) %>%
  mutate(i722_pad = (i722 - mean(i722))/sdp(i722)) %>%
  arrange(desc(i722_pad))

# calcular indicador pesquisas com o termo 'simples nacional'
i723 <- top100_mun_cod %>% left_join(termo_simplesnacional, by = c("nome" = "City")) %>% 
  replace_na(list(SIMPLES.Nacional...2020. = 0)) %>%
  rename(i723 = SIMPLES.Nacional...2020.) %>%
  mutate(i723_pad = (i723 - mean(i723))/sdp(i723)) %>%
  arrange(desc(i723_pad))

# calcular indicador pesquisas com o termo 'senac'
i724 <- top100_mun_cod %>% left_join(termo_senac, by = c("nome" = "City")) %>% 
  replace_na(list(Senac...2020. = 0)) %>%
  rename(i724 = Senac...2020.) %>%
  mutate(i724_pad = (i724 - mean(i724))/sdp(i724)) %>%
  arrange(desc(i724_pad))

# exportar indicadores do determinante cultura
write.csv(i711, "i711.csv", row.names = FALSE)
write.csv(i712, "i712.csv", row.names = FALSE)
write.csv(i721, "i721.csv", row.names = FALSE)
write.csv(i722, "i722.csv", row.names = FALSE)
write.csv(i723, "i723.csv", row.names = FALSE)
write.csv(i724, "i724.csv", row.names = FALSE)  
