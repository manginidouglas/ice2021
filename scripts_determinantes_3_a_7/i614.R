library(tidyverse)

# Indicador Nota Media no ENEM (i614)

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
# PASSO 2: obter notas medias no ENEM
# ------------------------------------------------------------------

# calculamos a nota media de cada aluno considerando as 5 provas (ciencias naturais, ciencas humanas, matematica, redacao, linguagens e codigos)
nota_media_ENEM <- ENEM_100mun %>% 
  mutate(nota_media = (NU_NOTA_CH + NU_NOTA_CN + NU_NOTA_LC + NU_NOTA_MT + NU_NOTA_REDACAO)/5) %>% 
                select (-Q001, -Q002, -NU_ANO, -NU_NOTA_CH, -NU_NOTA_CN, -NU_NOTA_LC, -NU_NOTA_MT, -NU_NOTA_REDACAO, -CO_MUNICIPIO_RESIDENCIA, -CO_ESCOLA, -TP_ST_CONCLUSAO, -TP_ENSINO) %>%
                drop_na()
# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

# calculamos o indicador
i614 <- nota_media_ENEM %>% 
  group_by(id_municipio, nome, sigla_uf) %>% 
  summarise(i614 = mean(nota_media)) %>%
  ungroup() %>%
  mutate(i614_pad = (i614 - mean(i614))/sdp(i614)) %>%
  arrange(desc(i614_pad))

# exportamos o indicador
write.csv(i614, "i614.csv", row.names = FALSE)