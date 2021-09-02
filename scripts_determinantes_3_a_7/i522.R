library(readxl)
library(tidyverse)
library("basedosdados")

# Indicador Tamanho da Industria Inovadora (i522)

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

# ------------------------------------------------------------------
# PASSO 1: obter numero de empresas de industria inovadora
# ------------------------------------------------------------------

# importar planilha com classificacao cnae de empresas
cnae <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd52 Outputs/i522/CNAE20_EstruturaDetalhada.xls', skip = 2) %>%
  select(classe = Classe, 
         denom = Denominação)

# remover "-" e "." das classes CNAE
cnae$classe = gsub('[[:punct:]]', '', cnae$classe)

# importar planilha do ICE 2020 com classes de industria inovadora
cnae_ice <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/d5 Inovação/sd52 Outputs/i522/Indicador Tamanho da Indústria Inovadora.xlsx', sheet = 2) %>%
  select(denom = "CNAE 2.0 Classe") %>%
  inner_join(cnae, by = 'denom') %>%
  na.omit()

# obter numero de empresas de industria inovadora a partir da RAIS estabelecimentos
query <- "SELECT ano, id_municipio, cnae_2 
FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
WHERE ano = 2019
AND id_municipio IN ('3550308','3304557','5300108','2927408','2304400','3106200','1302603','4106902','2611606','5208707','1501402','4314902','3518800'
,'3509502','2111300','3304904','2704302','3301702','5002704','2408102','2211001','3548708','3303500','2507507','3549904','3547809'
,'3543402','2607901','3534401','3170206','3552205','3118601','2800308','2910800','5103403','4209102','5201405','4113700','3136702'
,'1100205','1500800','3205002','4305108','3303302','3300456','1600303','3301009','4205407','3205200','3529401','3305109','3549805'
,'3530607','3106705','3548500','4115200','3513801','3525904','1400100','3143302','1200401','2504009','3538709','3510609','2609600'
,'5201108','3201308','3506003','3523107','3551009','3205309','2604106','2303709','4202404','3516200','4119905','2611101','4304606'
,'4314407','2933307','3154606','3170107','2610707','4104808','3541000','4125506','3518701','3554102','3526902','3303906','1506807'
,'1721000','2905701','2408003','3552502','3552809','5108402','3552403','4316907','4309209','1504208')"

estabelec <- read_sql(query)

estabelec_ice <- estabelec %>%
  group_by(id_municipio) %>%
  count(cnae_2, name = 'n_empresas') %>%
  inner_join(top100_mun_cod, by = 'id_municipio') %>%
  inner_join(cnae_ice, by = c('cnae_2' = 'classe')) %>%
  group_by(id_municipio, nome, sigla_uf) %>%
  summarise(empresas_inovadoras = sum(n_empresas)) %>%
  arrange(desc(empresas_inovadoras))

# ------------------------------------------------------------------
# PASSO 2: obter numero de empresas com mais de um funcionario
# ------------------------------------------------------------------

# acessar RAIS estabelecimento pelo Base dos Dados para obter numero de empresas com pelo menos um funcionario em cada municipio
vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019", 
  page_size = 300000)

temvinculo <- vinculos %>% 
  filter(qtde_vinculos_ativos != 0) %>%
  group_by(id_municipio) %>%
  summarise(n_empresas = n()) %>%
  right_join(top100_mun_cod, by = "id_municipio") %>%
  select(id_municipio, nome, sigla_uf,n_empresas) %>%
  arrange(desc(n_empresas))

# ------------------------------------------------------------------
# PASSO 3: calcular indicador
# ------------------------------------------------------------------

i522 <- temvinculo %>% 
  inner_join(estabelec_ice, by = c('id_municipio', 'nome', 'sigla_uf')) %>%
  mutate(i522 = empresas_inovadoras/n_empresas,
         i522_pad = (i522 - mean(i522))/sdp(i522)) %>%
  select(id_municipio, nome, sigla_uf, i522, i522_pad) %>%
  arrange(desc(i522_pad))

# exportar indicador
write.csv(i522, "i522.csv", row.names = FALSE)
