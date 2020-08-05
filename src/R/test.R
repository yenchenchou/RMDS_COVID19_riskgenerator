library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(sjmisc)
library(roxygen2)

# load data ---------------------------------------------------------------

days <- c('0624','0701','0708')

poi <- read_csv('../../data/processed/RMDS_poi.csv')
poi_area <- read_csv('../../data/processed/RMDS_poi_area_square_feet.csv')
open_hours <- read_csv('../../data/processed/RMDS_open_hours.csv')
case_death_table <- read_csv('../../data/external/LA_County_Covid19_CSA_case_death_table.csv')
testing_table <- read_csv('../../data/external/LA_County_Covid19_CSA_testing_table.csv')
file_1 <- read_csv(paste0('../../data/weekly_pattern/patterns-',days[1],'-part1.csv'))
file_2 <- read_csv(paste0('../../data/weekly_pattern/patterns-',days[2],'-part1.csv'))
file_3 <- read_csv(paste0('../../data/weekly_pattern/patterns-',days[3],'-part1.csv'))

# break data into 4 parts, use only the first part to test
file_size <- data.frame("part_1" = c(round(0.25*dim(file_1)[1]),
                                     round(0.25*dim(file_2)[1]),
                                     round(0.25*dim(file_3)[1]))) %>% 
  mutate("part_2" = part_1 * 2,
         "part_3" = part_1 * 3)

file_1 <- file_1[1:file_size[1,1],]
file_2 <- file_2[1:file_size[2,1],]
file_3 <- file_3[1:file_size[3,1],]


# calculate risk score ----------------------------------------------------


risk <- main(file_1, file_2, file_3,
             poi, poi_area, open_hours,
             case_death_table, testing_table) 

# write_csv(risk,"risk_1-16_data.csv")
