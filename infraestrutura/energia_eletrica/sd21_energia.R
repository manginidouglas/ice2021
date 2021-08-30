library(readxl)
library(tidyverse)

df <- read_excel(
  "infraestrutura/energia_eletrica/RankingB1-24-08-2021.xlsx")

tarifa <- df %>%
  select(dist= Distribuidora, sigla_uf= UF, tarifa= `Tarifa Convencional`)%>%
  mutate(dist = dist %>% str_to_lower())


mudar_dist <- c("boa vista" = "roraima energia",
                "equatorial pa" = "celpa",
                "equatorial al" = "ceal",
                "equatorial pi" = "cepisa",
                "eletropaulo" = "enel sp",
                "cebdis" = "ceb-dis",
                "celg-d" = "enel go",
                "celesc dis" = "celesc-dis",
                "copel dis"= "copel-dis",
                "rge" = "rge (agrupada)"
)


dist <- read_csv("infraestrutura/energia_eletrica/distribuidoras.csv") %>%
  pivot_longer(matches("^d\\d$"), names_to = "isdist", values_to = "dist") %>%
  filter(!is.na(dist)) %>%
  select(!c(id_municipio_6,isdist,pop,sigla_uf)) %>%
  mutate(dist = dist %>% str_replace_all(mudar_dist)) %>%
  left_join(tarifa,by = "dist")%>%
  group_by(id_municipio) %>%
  mutate(tarifa_media = mean(tarifa))%>%
  distinct(id_municipio, .keep_all = TRUE) %>%
  arrange(nome)

write_excel_csv(dist, "dados_finais/sd21_energia.xlsx")
