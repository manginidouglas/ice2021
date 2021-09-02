library(openxlsx)
indicadores<- read.csv('pca/indicadores_completo.csv', stringsAsFactors =  FALSE)
indicadores_pca<- read.csv('pca/indicadores_pca.csv', stringsAsFactors =  FALSE)

write.xlsx(indicadores, 'indicadores.xlsx')

i323 <- read.csv('dados_finais/i323.csv', stringsAsFactors =  FALSE)
i411 <- read.csv('dados_finais/i411.csv', stringsAsFactors =  FALSE)
i412 <- read.csv('dados_finais/i412.csv', stringsAsFactors =  FALSE)
read.csv('dados_finais/i323.csv', stringsAsFactors =  FALSE)
 
