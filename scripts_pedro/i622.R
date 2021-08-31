library(data.table)
library(readxl)
library(tidyverse)

# Indicador Proporcao de Alunos Concluintes em Cursos de Alta Qualidade (i622)

# ------------------------------------------------------------------
# PASSO 0: preliminares
# ------------------------------------------------------------------

# definimos uma fun√ß√£o para desvio padrao populacional
sdp <- function(x) {
  sd(x)*(sqrt((length(x)-1)/length(x)))
}

# importamos tabela com dados dos municipios mais populosos
top100_mun_cod <- read.csv("top100_mun_cod.csv", stringsAsFactors = FALSE)
top100_mun_cod <- top100_mun_cod %>% 
  transform(id_municipio = as.numeric(id_municipio))

# ------------------------------------------------------------------
# PASSO 1: obter concluintes em cursos avaliados pelo enade
# ------------------------------------------------------------------

# importando os dados. as planilhas s√£o baixadas no site do INEP
conceito_enade2017 = read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd62/resultados_conceito_enade_2017.xlsx")
conceito_enade2018 = read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd62/resultados_conceito_enade_2018.xlsx")
conceito_enade2019 = read_excel("C:/Users/User/OneDrive/Documentos/ICE 2021/d6 Capital Humano/sd62/Conceito_Enade_2019.xlsx")

# juntando as bases de conceito
conceito_enade = bind_rows(conceito_enade2017, conceito_enade2018, conceito_enade2019)

# selecionar apenas os cursos dos 100 municipios mais populosos
enade_ice <- top100_mun_cod %>% 
                      left_join(conceito_enade, by = c("id_municipio" = "CÛdigo do MunicÌpio")) %>% 
                      select(-"MunicÌpio do Curso", - "Sigla da UF") %>%
                      rename(enade_faixa = "Conceito Enade (Faixa)",
                             concl_inscritos = "N∫ de Concluintes Inscritos")

enade_ice_resumo <- enade_ice %>% 
  group_by(id_municipio, nome, sigla_uf,  enade_faixa) %>% 
  summarise(concluintes = sum(concl_inscritos))

# Obter total de concluintes em todos cursos avaliados pelo ENADE
concl_grad <- enade_ice_resumo %>% 
              group_by(id_municipio, nome, sigla_uf) %>% 
              summarise(tot_concl = sum(concluintes))


# obter total de concluintes em cursos com nota 4 ou 5 no ENADE
concl_alta_quali <- enade_ice_resumo %>% 
                    filter(enade_faixa== 4 | enade_faixa==5) %>% 
                    group_by(id_municipio, nome, sigla_uf) %>% 
                    summarise(tot_alta_quali = sum(concluintes))

# ------------------------------------------------------------------
# PASSO 2: calcular indicador
# ------------------------------------------------------------------

#calcular indice 
i622 <- concl_grad %>% 
        left_join(concl_alta_quali, by = c("id_municipio", "nome", "sigla_uf")) %>%
        replace_na(list(tot_alta_quali = 0)) %>%
        mutate(i622 = tot_alta_quali/tot_concl) %>%
        transform(i622 = as.numeric(i622)) %>%
        mutate(i622_pad =  (i622 - mean(i622))/sdp(i622))  %>%
        select(id_municipio, nome, sigla_uf, i622, i622_pad) %>%
        arrange(desc(i622_pad))

# salvamos o arquivo
write.csv(i622, "i622.csv", row.names = FALSE)          
          
