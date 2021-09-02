library(tidyverse)
library("basedosdados")
library(readxl)

# Indicador Prop. de Matriculados no Ensino Tecnico e Profissionalizante (i615)

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
# PASSO 1: obter numero de inscritos no ensino tecnico
# ------------------------------------------------------------------

query <- "SELECT ano, id_municipio, sigla_uf, idade_referencia, etapa_ensino FROM `basedosdados.br_inep_censo_escolar.matricula` 
WHERE ano = 2020
AND (etapa_ensino IN ('30','31','32','33','34','35','36','37','38','39','40','67','68','73','74'))
AND id_municipio IN ('3550308','3304557','5300108','2927408','2304400','3106200','1302603','4106902','2611606','5208707','1501402','4314902','3518800'
,'3509502','2111300','3304904','2704302','3301702','5002704','2408102','2211001','3548708','3303500','2507507','3549904','3547809'
,'3543402','2607901','3534401','3170206','3552205','3118601','2800308','2910800','5103403','4209102','5201405','4113700','3136702'
,'1100205','1500800','3205002','4305108','3303302','3300456','1600303','3301009','4205407','3205200','3529401','3305109','3549805'
,'3530607','3106705','3548500','4115200','3513801','3525904','1400100','3143302','1200401','2504009','3538709','3510609','2609600'
,'5201108','3201308','3506003','3523107','3551009','3205309','2604106','2303709','4202404','3516200','4119905','2611101','4304606'
,'4314407','2933307','3154606','3170107','2610707','4104808','3541000','4125506','3518701','3554102','3526902','3303906','1506807'
,'1721000','2905701','2408003','3552502','3552809','5108402','3552403','4316907','4309209','1504208')"
educ_prof <- read_sql(query)

# contamos a quantidade de alunos matriculados na Educacao Profissional em cada municipio
matriculados_EP <- educ_prof %>% 
  count(id_municipio, sigla_uf, sort = TRUE) %>% 
  rename(matriculados_EP = n)

# ------------------------------------------------------------------
# PASSO 2: obter populacao de 15 ou mais em 2010
# ------------------------------------------------------------------

# importamos tabela do censo 2010 com dados de populacao por municipio e idade
censo2010 <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd61 Acesso e Qualidade da Mão de Obra Básica/Downloads/censo2010.xlsx", skip = 6)
pop_mais15 <- top100_mun_cod %>% 
  left_join(censo2010, by = c("id_municipio" = "Cód.")) %>% 
  select(id_municipio, nome, sigla_uf, Total, "15 a 19 anos", "20 a 24 anos", "25 a 29 anos", 38:55 ,-"Idade ignorada", -"80 anos ou mais",-Total) %>%
  mutate(pop_mais15 = rowSums(across(where(is.numeric))))

# ------------------------------------------------------------------
# PASSO 3: obter populacao dos municipios em 2010
# ------------------------------------------------------------------

# importar tabela com populacao total dos municipios em 2010
query <- "SELECT * FROM `basedosdados.br_ibge_populacao.municipio` WHERE ano = 2010"
pop_2010 <- read_sql(query)

# ------------------------------------------------------------------
# PASSO 4: obter estimativa populacional de 2021
# ------------------------------------------------------------------

# obter populacao de 2021
pop_2021 <- read_excel('C:/Users/User/OneDrive/Documentos/ICE 2021/estimativa_dou_2021.xls', sheet = 2, skip = 1) %>%
  na.omit() %>%
  select(nome = 'NOME DO MUNICÍPIO',
         sigla_uf = 'UF',
         populacao = 'POPULAÇÃO ESTIMADA') %>%
  inner_join(top100_mun_cod, by = c('nome', 'sigla_uf'))

# ------------------------------------------------------------------
# PASSO 5: calcular fator de crescimento populacional 
# ------------------------------------------------------------------

# calcular fator de crescimento populacional
cresc_pop <- pop_2010 %>% inner_join(pop_2021, by = "id_municipio", suffix = c("_2010", "_2021")) %>% 
  mutate(cresc_pop = populacao_2021/populacao_2010) %>%
  select (-ano, -populacao_2010, -populacao_2021)

# ------------------------------------------------------------------
# PASSO 6: calcular populacao estimada com mais de 15 em 2021
# ------------------------------------------------------------------

# Calcular populacao estimada em cada municipio acima de 15 anos
pop_mais15_atual <- pop_mais15 %>% inner_join(cresc_pop, by = c("id_municipio", "nome", "sigla_uf")) %>%
  mutate(pop_mais15_atual = pop_mais15 * cresc_pop) %>%
  select(id_municipio, nome, sigla_uf, pop_mais15_atual)

# ------------------------------------------------------------------
# PASSO 7: calcular indicador
# ------------------------------------------------------------------

# por fim, calculamos o indice 
i615 <- pop_mais15_atual %>% inner_join(matriculados_EP, by = c("id_municipio", "sigla_uf")) %>% 
  mutate(i615 = matriculados_EP/pop_mais15_atual) %>%
  mutate(i615_pad =  (i615 - mean(i615))/sdp(i615))%>%
  select(id_municipio, nome, sigla_uf, i615, i615_pad) %>%
  arrange(desc(i615_pad))

# salvamos o arquivo
write.csv(i615, "i615.csv", row.names = FALSE)  
 