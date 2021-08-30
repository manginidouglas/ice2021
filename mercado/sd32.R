library(tidyverse)
library(basedosdados)

municode <- read_csv("municode.csv") %>%
  select(id_municipio, sigla_uf, nome) %>%
  mutate(id_municipio = as.character(id_municipio))

# pib per capita ----------------------------------------------------------

basedosdados::set_billing_id("ice2021")

# puxa populacao e pib municipal de todos os municipios
df <- tibble(
  query = c(
    "SELECT * 
     FROM `basedosdados.br_ibge_populacao.municipio`
     WHERE ano = 2018",
    
    "SELECT id_municipio, pib 
     FROM `basedosdados.br_ibge_pib.municipio` 
    WHERE ano = 2018")) %>%
  mutate(resultados = query %>% map( ~basedosdados::read_sql(.x))) %>%
  pull(resultados) %>%
  reduce(full_join)

# calcula pib per capita  
  df2 <- df %>%
  right_join(municode) %>%
  select(ano, id_municipio,nome,populacao,pib) %>%
  mutate(sd32_pib_capita  = pib/populacao)


write_excel_csv(df2, "dados_finais/sd32_pib_capita.xlsx")

# proporcao empresas grandes e medias sobre medias e pequenas -------------

vinculos <- basedosdados::read_sql(
  "SELECT ano, id_municipio, qtde_vinculos_ativos,tamanho_estabelecimento 
  FROM `basedosdados.br_me_rais.microdados_estabelecimentos` 
  WHERE ano = 2019 AND qtde_vinculos_ativos != 0", 
  page_size = 200000 # linhas por página na query
)

df <- vinculos %>%
  select(id_municipio, qtde_vinculos_ativos) %>% 
  mutate(qtde_vinculos_ativos = as.integer(qtde_vinculos_ativos), 
         pequena = between(qtde_vinculos_ativos,10,49),
         media = between(qtde_vinculos_ativos,50,249),
         grande = qtde_vinculos_ativos > 250) %>%
  group_by(id_municipio) %>%
  summarise(across(where(is.logical), ~sum(.x))) %>%
  right_join(municode) %>%
  select(id_municipio,sigla_uf,nome,everything()) %>%
  mutate(m_p = media/pequena, g_m = grande/media, mp_gm = m_p/g_m) %>%
  arrange(-mp_gm)

write_excel_csv(df,"dados_finais/sd32_prop_empresas.xlsx")
