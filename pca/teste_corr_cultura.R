library(tidyverse)

# sc == sem cultura
# cc == com cultura

sc <- readxl::read_excel("pca/ICE2021_sem_cultura.xls")

cc <- readxl::read_excel("pca/ICE2021.xls")

ccr <- select(cc,1:3,last_col())
scr <- select(sc, 1:3,last_col())

cor.test(ccr$ice_final, scr$ice_final, method = "spearman")
