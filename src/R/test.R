library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(sjmisc)
library(roxygen2)
# load data ---------------------------------------------------------------
days <- c('0624','0701','0708')

poi <- read_csv('data/processed/RMDS_poi.csv')
poi_area <- read_csv('data/processed/RMDS_poi_area_square_feet.csv')
open_hours <- read_csv('data/processed/RMDS_open_hours.csv')
case_death_table <- read_csv('data/external/LA_County_Covid19_CSA_case_death_table.csv')
testing_table <- read_csv('data/external/LA_County_Covid19_CSA_testing_table.csv')
file_1_clean <- read_csv(paste0('data/processed/patterns-',days[1],'.csv'))
file_2_clean <- read_csv(paste0('data/processed/patterns-',days[2],'.csv'))
file_3_clean <- read_csv(paste0('data/processed/patterns-',days[3],'.csv'))
;
# preclean SafeGraph weekly pattern data ----------------------------------

# no need to run this again for testing
# days <- c('0624','0701','0708')
# 
# for (i in c(1,2,3)){
#     nam <- paste0("file_",i,"_clean")
#     file_1 <- read_csv(paste0('../../data/weekly_pattern/raw/patterns-',days[i],'-part1.csv'))
#     file_2 <- read_csv(paste0('../../data/weekly_pattern/raw/patterns-',days[i],'-part2.csv'))
#     file_3 <- read_csv(paste0('../../data/weekly_pattern/raw/patterns-',days[i],'-part3.csv'))
#     file_4 <- read_csv(paste0('../../data/weekly_pattern/raw/patterns-',days[i],'-part4.csv'))
#     file_clean <- sg_data_cleaning(file_1, poi) %>%
#       rbind(sg_data_cleaning(file_2, poi)) %>%
#       rbind(sg_data_cleaning(file_3, poi)) %>%
#       rbind(sg_data_cleaning(file_4, poi))
#     assign(nam, file_clean)
#     rm(file_1, file_2, file_3, file_4)
#     write_csv(file_clean, paste0('../../data/weekly_pattern/patterns-',days[i],'.csv'))
#     print(paste0('successfully clean patterns-',days[i],'.csv'))
#     rm(file_clean)
# }

# calculate risk score ----------------------------------------------------

risk <- main(file_1_clean, file_2_clean, file_3_clean,
            poi, poi_area, open_hours,
            case_death_table, testing_table) 

sum(risk$risk_score!=-1)

risk_final <- risk %>% 
  select(location_name, top_category, latitude, longitude, street_address, postal_code, city, community, risk_score, risk_level, update_date) %>% 
  rename(`Time Stamp` = update_date, Region = community, Latitude = latitude, Longitude = longitude, `Risk-Score` = risk_score, `Risk-Level` = risk_level)
write_csv(risk_final,"data/result/risk.csv")
