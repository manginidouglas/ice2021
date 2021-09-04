library(magrittr)
library(tidyverse)

ranking <- readxl::read_excel("pca/ICE2021.xls") %>%
  dplyr::select(1:3, 145:149) %>%
  dplyr::mutate(across(contains("ice"),  ~ round(., digits = 3)))

readr::write_csv(ranking, "pca/ranking_ice_2021_final.csv")


# produz a tabela final ---------------------------------------------------

# nomes dos indicadores ---------------------------------------------------
nomes_i <- tibble(
  nomes = c(
    'id_municipio id_municipio',
    'sigla_uf sigla_uf',
    'nome nome',
    'i111 Tempo de Viabilidade de Localização', 
    'i112 Tempo de Registro, Cadastro e Viabilidade de Nome', 
    'i113 Taxa de Congestionamento em Tribunais',
    'i121 Alíquota Interna do ICMS',
    'i121 Alíquota Interna do IPTU',
    'i123 Alíquota Interna do ISS',
    'i124 Qualidade de Gestão Fiscal',
    'i131 Simplicidade Tributária',
    'i132 CNDs Municipais',
    'i133 Atualização de Zoneamento',
    'i211 Conectividade Via Rodovias',
    'i212 Número de Decolagens por Ano',
    'i213 Distância ao Porto mais Próximo',
    'i221 Acesso à Internet Rápida',
    'i222 Preço Médio do m²',
    'i223 Custo da Energia Elétrica',
    'i224 Taxa de Homicídios',
    'i311 Índice de Desenvolvimento Humano',
    'i312 Crescimento Real Médio do PIB',
    'i313 Número de Empresas Exportadoras com Sede na Cidade',
    'i321 PIB per capita',
    'i322 Proporção entre Grandes/Médias e Médias/Pequenas Empresas',
    'i323 Compras Públicas',
    'i411 Operações de Crédito por Município',
    'i412 Proporção Relativa de Capital de Risco',
    'i413 Capital Poupado per capita',
    'i511 Proporção de Mestres e Doutores em C&T',
    'i512 Proporção de Funcionários em C&T',
    'i513 Média de Investimentos do BNDES e FINEP',
    'i514 Infraestrutura Tecnológica',
    'i515 Contratos de Concessão',
    'i521 Patentes',
    'i522 Tamanho da Indústria Inovadora',
    'i523 Tamanho da Economia Criativa',
    'i524 Tamanho das Empresas TIC',
    'i611 Nota do Ideb',
    'i612 Proporção de Adultos com pelo menos o Ensino Médio Completo',
    'i613 Taxa Líquida de Matrícula no Ensino Médio',
    'i614 Nota Média no ENEM',
    'i615 Proporção de Matriculados no Ensino Técnico e Profissionalizante',
    'i621 Proporção de Adultos com pelo menos os Ensino Superior Completo',
    'i622 Proporção de Alunos Concluintes em Cursos de Alta Qualidade',
    'i623 Custo Médio de Salários de Dirigentes',
    'i711 Pesquisas pelo Termo Empreendedor',
    'i712 Pesquisas pelo Termo MEI',
    'i721 Pesquisas por Sebrae',
    'i722 Pesquisas por Franquia',
    'i723 Pesquisas por SIMPLES Nacional',
    'i724 Pesquisas por Senac')) %>%
  separate(nomes, c("i", "nome_i"), sep = " ", extra = "merge")




# separa colunas ----------------------------------------------------------
ice_bruto <- readxl::read_excel("pca/ICE2021.xls")

get_data <- function(pattern) {
  
  ice_bruto %>%
  select(1:3, matches(pattern)) %>%
    mutate(across(-(1:3), ~round(.x, digits = 4)))
  
  }

i <- get_data("^i\\d{3}$") %>%
  set_names(nomes_i$nome_i)

i_pad <- get_data("^i\\d{3}_linha$") %>%
  set_names(nomes_i$nome_i)

sd <-get_data("^s\\d{2}$")

sd_pad <-get_data("^s\\d{2}_linha$")

d <- get_data("^d\\d$")

d_pad <- get_data("^d\\d_linha$")

ranking_final <- get_data("ice")

dfs <- list("indicadores" = i, 
            "indicadores_pad" = i_pad,
            "subdeterminantes" = sd,
            "subdeterminantes_pad" = sd_pad,
            "determinantes" = d,
            "determinantes_pad" = d_pad,
            "ranking_final" = ranking_final)

openxlsx::write.xlsx(dfs, file = "pca/dados_bonitos.xlsx",
                      overwrite = TRUE)


