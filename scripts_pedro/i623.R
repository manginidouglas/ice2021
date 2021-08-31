library(readxl)
library(tidyverse)
library("basedosdados")

#  Indicador Custo Medio de Salarios de Dirigentes (i623)

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
# PASSO 1: obter dados na RAIS de dirigentes
# ------------------------------------------------------------------

# importamos tabela com as ocupacoes da CBO 2002 de interesse (subgrupos principais 12, 13 e 14) feita manualmente
# essa tabela nao e usada diretamente neste codigo, mas e usada para auxiliar a criacao da query no Banco dos Dados
ocupacoes <- read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd62/CBO2002 - Ocupação Subgrupo Principal 12 13 14.xlsx", 
                        col_types = c("text", "text"))

# importamos os dados da RAIS com vinculos de interesse e dos municipios de interesse (100 mais populosos)
query <- "SELECT valor_remun_media_nominal, ano, id_municipio, cbo_2002 
FROM `basedosdados.br_me_rais.microdados_vinculos` 
WHERE ano = 2019
AND cbo_2002 IN ('121005','121010','122105','122110','122115','122120','122205','122305'
,'122405','122505','122510','122515','122520','122605','122610','122615'
,'122620','122705','122710','122715','122720','122725','122730','122735'
,'122740','122745','122750','122755','123105','123110','123115','123205'
,'123210','123305','123310','123405','123410','123605','123705','123805'
,'131105','131110','131115','131120','131205','131210','131215','131220'
,'131225','131305','131310','131315','131320','141105','141110','141115'
,'141120','141205','141305','141405','141410','141415','141420','141505'
,'141510','141515','141520','141525','141605','141610','141615','141705'
,'141710','141715','141720','141725','141730','141735','141805','141810'
,'141815','141820','141825','141830','142105','142110','142115','142120'
,'142125','142130','142205','142210','142305','142310','142315','142320'
,'142325','142330','142335','142340','142345','142350','142405','142410',
'142415','142505','142510','142515','142520','142525','142530','142535',
'142605','142610','142705','142710')
AND id_municipio IN ('3550308','3304557','5300108','2927408','2304400','3106200','1302603','4106902','2611606','5208707','1501402','4314902','3518800'
,'3509502','2111300','3304904','2704302','3301702','5002704','2408102','2211001','3548708','3303500','2507507','3549904','3547809'
,'3543402','2607901','3534401','3170206','3552205','3118601','2800308','2910800','5103403','4209102','5201405','4113700','3136702'
,'1100205','1500800','3205002','4305108','3303302','3300456','1600303','3301009','4205407','3205200','3529401','3305109','3549805'
,'3530607','3106705','3548500','4115200','3513801','3525904','1400100','3143302','1200401','2504009','3538709','3510609','2609600'
,'5201108','3201308','3506003','3523107','3551009','3205309','2604106','2303709','4202404','3516200','4119905','2611101','4304606'
,'4314407','2933307','3154606','3170107','2610707','4104808','3541000','4125506','3518701','3554102','3526902','3303906','1506807'
,'1721000','2905701','2408003','3552502','3552809','5108402','3552403','4316907','4309209','1504208')"
dirigentes <- read_sql(query)

# filtrar linhas em que a remuneracao declarada nao e zero 
dirigentes <- dirigentes %>% filter(valor_remun_media_nominal != 0)

# contabilizar total de trabalhadores nos cargos de interesse
dirigentes_mun <- top100_mun_cod %>% 
                  left_join(dirigentes, by = "id_municipio") %>% 
                  count(id_municipio, nome, sigla_uf, name = "n_dirigentes", sort = TRUE)

# contabilizar a soma dos salarios para os cargos de interesse em cada municipio
dirigentes_sal <- top100_mun_cod %>% left_join(dirigentes, by = "id_municipio") %>%
                  group_by(id_municipio, nome, sigla_uf) %>%
                  summarise(salario_dirigentes = sum(valor_remun_media_nominal))

# ------------------------------------------------------------------
# PASSO 2: calcular indicador
# ------------------------------------------------------------------

#calcular indice i623
i623 <- dirigentes_mun %>% 
        inner_join(dirigentes_sal, by = c("id_municipio", "nome", "sigla_uf")) %>%
        mutate(i623 = salario_dirigentes/n_dirigentes) %>%
        mutate(i623_pad =  (i623 - mean(i623))/sdp(i623)) %>%
        select(id_municipio, nome, sigla_uf, i623, i623_pad) %>%
        arrange(desc(i623_pad))

# salvamos o arquivo
write.csv(i623, "i623.csv", row.names = FALSE)          
