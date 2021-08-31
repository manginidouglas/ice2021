library(readxl)
library(tidyverse)
library("basedosdados")

# Indicador Proporcao de Mestres e Doutores em C&T (i511)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# Definir projeto no Google Cloud
set_billing_id("workshop-teste-322616")

# definimos uma funcao para desvio padrao populacional
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio))

# criar variavel com municipios ICE em letra maiuscula 
# (dados da CAPES tem municipios com letra maiuscula)
top100_mun_cod$NOME = toupper(top100_mun_cod$nome)

# ------------------------------------------------------------------
# PASSO 1: obter dados sobre discentes
# ------------------------------------------------------------------

# obter dados sobre discentes da CAPES para o ano de referencia 2019
discentes <- read.csv2("C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/
                       sd51 Inputs/i511/
                       br-capes-colsucup-discentes-2019-2021-03-01.csv", 
                       row.names=NULL)

# definir vetor com areas de avaliacao de interesse
alvo <- c('ASTRONOMIA / FÍSICA',
          'BIOTECNOLOGIA',
          'CIÊNCIA DA COMPUTAÇÃO', 
          'CIÊNCIA DE ALIMENTOS', 
          'CIÊNCIAS AGRÁRIAS I', 'CIÊNCIAS AMBIENTAIS', 
          'CIÊNCIAS BIOLÓGICAS I', 
          'CIÊNCIAS BIOLÓGICAS II', 
          'CIÊNCIAS BIOLÓGICAS III', 
          'ENGENHARIAS I', 
          'ENGENHARIAS II', 
          'ENGENHARIAS III', 
          'ENGENHARIAS IV', 
          'FARMÁCIA', 
          'GEOCIÊNCIAS', 
          'MATEMÁTICA / PROBABILIDADE E ESTATÍSTICA', 
          'MATERIAIS', 'QUÍMICA')

# filtrar para obter apenas as situacoes "titulado" 
# e as areas de interesse e municipios de interesse
disc_titulados <- discentes %>% filter(NM_SITUACAO_DISCENTE == "TITULADO",
                                       NM_AREA_AVALIACAO %in% alvo) %>%
                  rename(sigla_uf = SG_UF_PROGRAMA,
                         NOME = NM_MUNICIPIO_PROGRAMA_IES) %>%
                  inner_join(top100_mun_cod, by = c("sigla_uf", "NOME")) %>%
                  count(sigla_uf, nome, name = "disc_titulados") %>%
                  right_join(top100_mun_cod, by = c("sigla_uf","nome")) %>%
                  select(id_municipio, nome, sigla_uf, disc_titulados) %>%
                  replace_na(list(disc_titulados = 0))

# ------------------------------------------------------------------
# PASSO 2: obter dados sobre empresas
# ------------------------------------------------------------------

# acessar RAIS estabelecimento pelo Base dos Dados
# para obter numero de empresas com pelo menos um funcionario em cada municipio
vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019", 
  page_size = 300000
)

temvinculo <- vinculos %>% 
  filter(qtde_vinculos_ativos != 0) %>%
  group_by(id_municipio) %>%
  summarise(n_empresas = n()) %>%
  right_join(top100_mun_cod) %>%
  select(id_municipio, nome, sigla_uf,n_empresas) %>%
  arrange(desc(n_empresas))

# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

# calcular indicador i511
i511 <- temvinculo %>% 
  left_join(disc_titulados, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(i511 = disc_titulados/n_empresas) %>% 
  mutate(i511_pad =   (i511 - mean(i511))/sdp(i511)) %>%
  select(id_municipio, nome, sigla_uf, i511, i511_pad) %>%
  arrange(desc(i511_pad))
  
# salvamos o arquivo
write.csv(i511, "i511.csv", row.names = FALSE)   
