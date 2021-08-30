municode <- read_csv("municode.csv") %>%
  select(id_municipio_6,pop)
  

homicidios <- read_delim("infraestrutura/homicidios/dados_homicidios", 
                         skip = 1,
                         delim = ";", 
                         escape_double = FALSE, 
                         trim_ws = TRUE,
                         col_names = c("municipio","obitos")) %>%
  separate(col = municipio, 
           into = c("id_municipio_6","municipio"), 
           sep = " ",
           extra = "merge",
           convert = TRUE) %>%
  right_join(municode)%>% 
  mutate(taxa_homicidios = obitos/pop,
         inverso_taxa = 1/taxa_homicidios)

write_excel_csv(homicidios,"dados_finais/sd22_homicidios.xlsx")



