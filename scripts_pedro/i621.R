library(tidyverse)

# Indicador Proporcao de Adultos com pelo Menos Ensino Superior Completo (i621)

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
  transform(id_municipio = as.integer(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: obter dados do ENEM
# ------------------------------------------------------------------

#importamos a base de dados do ENEM
ENEM_2019 <- data.table::fread(input='C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd61 Acesso e Qualidade da Mão de Obra Básica/Downloads/DADOS/MICRODADOS_ENEM_2019.csv',
                               integer64='character',
                               skip=0,  #Ler do inicio
                               nrow=-1, #Ler todos os registros
                               na.strings = "", 
                               showProgress = TRUE)

# selecionamos variaveis de interesse
ENEM_2019 <- ENEM_2019 %>% 
  select(NU_INSCRICAO, 
         NU_ANO, 
         CO_MUNICIPIO_ESC, 
         CO_MUNICIPIO_RESIDENCIA, 
         CO_ESCOLA, 
         TP_ST_CONCLUSAO, 
         TP_ENSINO, 
         NU_NOTA_CH, 
         NU_NOTA_CN, 
         NU_NOTA_LC, 
         NU_NOTA_MT, 
         NU_NOTA_REDACAO, 
         Q001, 
         Q002)

# unimos as duas tabelas para selecionar apenas os inscritos dos 100 municipios mais populosos
ENEM_100mun <- top100_mun_cod %>% 
  left_join(ENEM_2019, by = c("id_municipio" = "CO_MUNICIPIO_ESC"))

# salvamos essa tabela para usar em outros indices
write.csv(ENEM_100mun, "ENEM_100mun.csv", row.names = FALSE)

# ------------------------------------------------------------------
# PASSO 1: alternativo
# ------------------------------------------------------------------

# importar dadoss ENEM dos munipios do ICE
ENEM_100mun <- read.csv('ENEM_100mun.csv')

# ------------------------------------------------------------------
# PASSO 2: dados do ENEM
# ------------------------------------------------------------------

# contamos a quantidade de inscritos por municipio
inscritos_mun <- ENEM_100mun %>% 
  count(id_municipio, nome, sigla_uf, sort = TRUE) %>% 
  rename(inscritos = n)

# criamos um vetor com as respostas do questionario que selecionam pai ou mae com ES completo (ver dicionario dos microdados ENEM 2019)
alvo_ES <- c("F", "G")

# contamos a quantidade de inscritos que declaram ter pai com ES completo
pai_ES <- ENEM_100mun %>% 
  filter(Q001 %in% alvo_ES) %>% 
  count(id_municipio, nome, sigla_uf, sort = TRUE) %>% 
  rename(pai_ES = n)

# contamos a quantidade de inscritos que declaram ter mae com ES completo
mae_ES <- ENEM_100mun %>% 
  filter(Q002 %in% alvo_ES) %>% 
  count(id_municipio, nome, sigla_uf, sort = TRUE) %>% 
  rename(mae_ES = n)

# juntamos as tres tabelas:
# inscritos totais, inscritos com pais com EM, incritos com mae com EM)
paimae_ES <- pai_ES %>% 
  inner_join(mae_ES, by = c('id_municipio', 'nome', 'sigla_uf')) %>% 
  inner_join(inscritos_mun, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(prop_paiES = pai_ES/inscritos,
         prop_maeES = mae_ES/inscritos) %>%
  mutate(i621= (prop_paiES + prop_maeES)/2)

# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

# calculamos e padronizamos o indice
i621 <- paimae_ES %>% 
  select(id_municipio, nome, sigla_uf, i621) %>% 
  transform(id_municipio = as.character(id_municipio)) %>% 
  mutate(i621_pad = (i621 - mean(i621))/sdp(i621)) 

# exportamos o indicador
write.csv(i621, "i621.csv", row.names = FALSE)
