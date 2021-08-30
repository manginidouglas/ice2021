# internet ----------------------------------------------------------------

municode <- read_csv("municode.csv") %>% select(id_municipio,pop)

df <- read_delim(
file = "infraestrutura/internet/Acessos_Banda_Larga_Fixa_2019-2020_Colunas.csv", 
  delim = ";", 
  escape_double = FALSE, 
  trim_ws = TRUE)

internet <- df %>%
  select(UF, 
         id_municipio = `Código IBGE Município`,
         Município,
         `Faixa de Velocidade`,
         `2020-01`:`2020-12`) %>%
  filter(`Faixa de Velocidade` %in% c("> 34Mbps","12Mbps a 34Mbps"))%>% 
  gather(`2020-01`:`2020-12`, key = "mes", value = "acessos")%>% 
  group_by(id_municipio,Município) %>%
  summarise(acessos = sum(acessos,na.rm = T)) %>%
  right_join(municode,keep = F) %>%
  mutate(acessos_hab = acessos/pop)

write_excel_csv(internet,"dados_finais/sd22_internet.xlsx")
