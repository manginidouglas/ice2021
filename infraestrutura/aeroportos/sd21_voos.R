library(tidyverse)
library(sf)
library(geobr)

# municipios --------------------------------------------------------------
mcoords <- read_municipality() %>% # coordenadas dos municipios
  select(id_municipio = 1, nome = 2, geom = 5)

municode <- read_csv("municode.csv") %>% 
  select(id_municipio, sigla_uf, nome) %>%
  mutate(nome = str_to_title(nome)) %>%
  left_join(mcoords, keep = FALSE)

# aeroportos br -----------------------------------------------------------

#unzip("infraestrutura/aeroportos/aerodromos-zip.zip",
#      exdir = "infraestrutura/aeroportos/voos_shapefiles",
#      junkpaths = TRUE, overwrite = TRUE)


aeroshp <- read_sf("infraestrutura/aeroportos/voos_shapefiles/Aerodromos.shp")

siglas_geo <- aeroshp %>%
  mutate(nm_municip = str_to_title(nm_municip)) %>%
  select(sigla_aero = cod_icao) # geometry is sticky

# voos 2020 -------------------------------------------------------------------
# unzip os dados apenas uma vez

#unzip("infraestrutura/aeroportos/Dados_Estatisticos.zip",
#      exdir = "infraestrutura/aeroportos/dados_voos",
#      junkpaths = TRUE, overwrite = TRUE)

# voos no mundo
voos <- read.delim(
  "infraestrutura/aeroportos/dados_voos/Dados Estat¡sticos.csv",sep = ";")

# no br
voos_br <- voos %>%
  as_tibble() %>% 
  select(ANO,MÊS,contains("AEROPORTO.DE.ORIGEM"), GRUPO.DE.VOO, DECOLAGENS) %>%
  filter(ANO == 2020, 
         AEROPORTO.DE.ORIGEM..PAÍS. == "BRASIL",
         GRUPO.DE.VOO == "REGULAR")%>%
  rename(sigla_aero = AEROPORTO.DE.ORIGEM..SIGLA.,
         nome = AEROPORTO.DE.ORIGEM..NOME.,
         sigla_uf = AEROPORTO.DE.ORIGEM..UF.) %>%
  mutate(nome = str_to_title(nome),
         sigla_uf = if_else(nome == "Guaíra","PR",sigla_uf)) %>% # dados errados 
  group_by(sigla_aero, sigla_uf, nome) %>%
  summarise(decolagens = sum(DECOLAGENS, na.rm = TRUE)) %>%
  ungroup()

# no br e nos 100 maiores munipios

decolagens <- voos_br %>%
  group_by(sigla_uf,nome) %>%
  summarise(decolagens = sum(decolagens, na.rm = TRUE)) %>%
  ungroup() %>%
  right_join(municode) %>%
  select(id_municipio,everything())%>% 
  arrange(id_municipio)

# nao estao na lista
naotem <- decolagens %>% filter(is.na(decolagens))

# geolocaliza os aeroportos br
voos_br<- left_join(voos_br, siglas_geo)

# data viz ----------------------------------------------------------------
#  br_airports <- ggplot()+
#  geom_sf(data = geobr::read_state())+ # mapa base com shapes dos estados br 
#  geom_sf(data = naotem$geometry, fill = "red")+
#    geom_sf(data = voos_br$geometry)+ 
#  theme(panel.background = element_blank(),
#        axis.text = element_blank(),
#        axis.ticks = element_blank())

# idsp <- naotem %>% filter(sigla_uf == "SP") %>% pull(id_municipio)
# sp <- filter(naotem, id_municipio %in% idsp)
# sp_voos <- filter(voos_br, sigla_uf == "SP") %>% pull(geometry)

# sp_airports <- ggplot()+
#  geom_sf(data = geobr::read_state(code_state = "SP"))+ 
#  geom_sf(data =  sp, fill = "red")+
#  geom_sf(data = sp_voos)+
#  theme(panel.background = element_blank(),
#        axis.text = element_blank(),
#        axis.ticks = element_blank())

# ggsave("infraestrutura/aeroportos/br_airports.png", br_airports)
# ggsave("infraestrutura/aeroportos/sp_airports.png", sp_airports)

# achar um aeroporto para os muni faltantes ------------------------------------

aeroprox <- function(id) {
  
  mun <- filter(naotem, id_municipio == id) %>%
    st_as_sf()
  
  r <- st_distance(mun, st_as_sf(voos_br), by_element = TRUE) %>%
    which.min()
  
  voos_br %>% filter(row_number() == r) %>%
    as.data.frame() %>%
   select(sigla_aero)
}  

# decolagens com base em aeroporto mais perto
siglas_faltantes <- naotem %>% 
  as.data.frame() %>% 
  pull(id_municipio) %>% 
  map(aeroprox) %>% 
  unlist() 

naotem <- naotem %>%
  as.data.frame() %>%
  select(1:3) %>%
  bind_cols(siglas_faltantes) %>%
  rename(sigla_aero = 4) %>%
  left_join(voos_br, by = "sigla_aero", suffix = c("","_ref")) %>%
  select(!geometry)

# colunas _ref NA significam aeroporto na cidade
sd21_voos<- decolagens %>%
  as.data.frame() %>%
  select(!geom) %>%
  filter(!is.na(decolagens)) %>%
  bind_rows(naotem) %>%
  arrange(-decolagens)

write_excel_csv(sd21_voos,"dados_finais/sd21_voos.xlsx")
