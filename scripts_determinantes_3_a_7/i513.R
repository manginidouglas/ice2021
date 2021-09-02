library(readxl)
library(tidyverse)
library("basedosdados")
library('readODS')

# Indicador Media de Investimentos do BNDES e da FINEP (i513)

# ------------------------------------------------------------------
# PASSO 0 : preliminares
# ------------------------------------------------------------------

# Definir projeto no Google Cloud
set_billing_id("workshop-teste-322616")

# definimos uma fun√ß√£o para desvio padrao populacional para ser usada mais a frente no c√≥digo
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.character(id_municipio))
top100_mun_cod$NOME = toupper(top100_mun_cod$nome)

# ------------------------------------------------------------------
# PASSO 1 : obter dados do BNDES
# ------------------------------------------------------------------

# importar tabela do BNDES com informacoes sobre investimentos nos municipios
bndes <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d5 InovaÁ„o/sd51 Inputs/i513/naoautomaticas.xlsx", skip = 4)

# selecionamos apenas os municipios do ICE, agrupamos e somamos por municipio os valores de 2020
bndes_ice <- top100_mun_cod %>% 
            left_join(bndes, by = c('id_municipio' = 'MunicÌpio - cÛdigo')) %>%
            rename(data = "Data da contrataÁ„o",
                   valor = "Valor contratado  R$") %>%
            filter(data >= as.POSIXct("2020-01-01"),
                  data <= as.POSIXct("2020-12-31")) %>%
            group_by(id_municipio, nome, sigla_uf) %>%
            summarise(contratado = sum(valor)) %>%
            arrange(desc(contratado)) %>%
            right_join(top100_mun_cod, by = c('id_municipio','nome','sigla_uf')) %>%
            replace_na(list(contratado = 0))

# ------------------------------------------------------------------
# PASSO 2: obter dados da FINEP
# ------------------------------------------------------------------

# importamos a tabela com informacoes sobre projetos contratados da FINEP
finep <- read_ods("C:/Users/User/OneDrive/Documentos/ICE 2021/d5 InovaÁ„o/sd51 Inputs/i513/17_08_2021_Contratacao.ods", skip = 5)

# alterar nomes e tipo de colunas de interesse
finep <- finep %>% rename(data = "Data Assinatura", valor = "Valor Finep", NOME = "MunicÌpio", sigla_uf = "UF")
finep$data = as.POSIXct(finep$data, format = "%d/%m/%Y")
finep$NOME = toupper(finep$NOME)

# filtrar para obter apenas contratos do ano de 2020, agrupar e somar valores de cada municipio
finep_2020 <- finep %>% 
              filter(data >= as.POSIXct("2020-01-01"),
                     data <= as.POSIXct("2020-12-31")) %>%
              group_by(NOME, sigla_uf) %>%
              summarise(contratado = sum(valor))

# separar municipios de interesse
finep_ice <- top100_mun_cod %>% 
            left_join(finep_2020, by = c('NOME', 'sigla_uf')) %>%
            replace_na(list(contratado = 0)) %>%
            select(-NOME) %>%
            arrange(desc(contratado))

# ------------------------------------------------------------------
# PASSO 3: obter numero de empresas com pelo menos um funcionario
# ------------------------------------------------------------------

# acessar RAIS estabelecimento pelo Base dos Dados para obter numero de empresas com pelo menos um funcionario em cada municipio
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
  right_join(top100_mun_cod, by = "id_municipio") %>%
  select(id_municipio, nome, sigla_uf,n_empresas) %>%
  arrange(desc(n_empresas))

# ------------------------------------------------------------------
# PASSO 4: calcular indicador i513 e salvar arquivo
# ------------------------------------------------------------------

i513 <- temvinculo %>% 
        inner_join(finep_ice, by = c('id_municipio','nome','sigla_uf')) %>%
        inner_join(bndes_ice, by = c('id_municipio','nome','sigla_uf'), suffix = c('_finep', '_bndes')) %>%
        mutate(i513 = (contratado_finep + contratado_bndes)/n_empresas) %>%
        mutate(i513_pad = (i513 - mean(i513))/sdp(i513)) %>%
        select(id_municipio, nome, sigla_uf, i513, i513_pad) %>%
        arrange(desc(i513_pad))

# salvamos o arquivo com o indicador
write.csv(i513, "i513.csv", row.names = FALSE) 
