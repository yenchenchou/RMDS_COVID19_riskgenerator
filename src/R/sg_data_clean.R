library(dplyr, quietly = TRUE)
library(tidyverse, quietly = TRUE) 

# define functions --------------------------------------------------------

#' @title preclean SafeGraph weekly pattern data
#' 
#' @description select only useful columns for risk score calcultation and points in CA
#' @import dplyr
#' @param sg_data SafeGraph weekly pattern data downloaded from https://catalog.safegraph.io/app/information
#' @param poi SafeGraph POI dataset (only contain CA data)
#' @export
sg_data_cleaning <- function(sg_data, poi){
  sg_data <- sg_data %>% 
    select(safegraph_place_id, 
           visits_by_day, 
           visits_by_each_hour, 
           median_dwell, 
           date_range_start,
           date_range_end) 
  # inner join to filter points only in CA
  sg_data <- sg_data %>% 
    merge(poi %>% select(safegraph_place_id), 
          by = "safegraph_place_id")
  print('match data with poi data successfully')
  return(sg_data)
}


#' @title bind SafeGraph weekly pattern data
#' 
#' @description bind 3 weeks SafeGraph weekly pattern data downloaded from https://catalog.safegraph.io/app/information
#' @import dplyr
#' @param week week number: 1, 2 or 3
#' @param poi SafeGraph POI dataset (only contain CA data)
#' @param path path where the file stored
#' @export
bind_sg_data <- function(week,poi,path){
  print('start loading data... may take a few minutes')
  file_1 <- read_csv(paste0(path,'/raw/patterns-',week,'-part1.csv'), col_types = cols())
  file_2 <- read_csv(paste0(path,'/raw/patterns-',week,'-part2.csv'), col_types = cols())
  file_3 <- read_csv(paste0(path,'/raw/patterns-',week,'-part3.csv'), col_types = cols())
  file_4 <- read_csv(paste0(path,'/raw/patterns-',week,'-part4.csv'), col_types = cols())
  print('data loaded successfully')
  file_clean <- sg_data_cleaning(file_1, poi) %>%
    rbind(sg_data_cleaning(file_2, poi)) %>%
    rbind(sg_data_cleaning(file_3, poi)) %>%
    rbind(sg_data_cleaning(file_4, poi))
  write_csv(file_clean, paste0(path,'/patterns-',week,'.csv'))
  print(paste0('successfully clean patterns-',week,'.csv'))
}

# load data ---------------------------------------------------------------

print('start cleaning SafeGraph data')
poi <- read_csv('../../data/processed/RMDS_poi.csv')
path <- '../../data/weekly_pattern'
for (i in c(1,2,3)){
  print(paste0('start processing week ',i,' data'))
  bind_sg_data(i,poi,path)
}
print('finish cleaning SafeGraph data!')
