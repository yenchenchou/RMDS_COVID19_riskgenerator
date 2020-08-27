library(readr, quietly = TRUE)
library(dplyr, quietly = TRUE)
library(tidyverse, quietly = TRUE)
library(purrr, quietly = TRUE)
library(stringr, quietly = TRUE)
library(tidyr, quietly = TRUE)
library(sjmisc, quietly = TRUE)
# library(roxygen2) 


# define functions --------------------------------------------------------

#' @title Get Daily Visits
#'
#' @description This function allows you to get information related to daily visits from SafeGraph weekly patterns dataset
#' @param x SafeGraph weekly patterns dataset
#' @return A dataframe containing daily visits for each weekday
#' @export
get_daily_visits <- function (x) {
  # select daily visit data
  x <- x %>%
    # select columns related to daily visits
    select(safegraph_place_id, visits_by_day, median_dwell) %>%
    # Parse visits_by_day [json] into columns in dataframe
    # Each represents a weekday: from Monday to Sunday
    mutate(visits_by_day = str_extract(visits_by_day, "([0-9]+,)+[0-9]")) %>%
    separate(visits_by_day, into = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
             sep = ",", convert = T) %>%
    # Gather: to make the data tidy
    gather(key = "weekday", value = "visits_by_day", -safegraph_place_id, -median_dwell)
  x
}

#' @title Get hourly visits
#'
#' @description This function allows you to get information related to hourly visits from SafeGraph weekly patterns dataset
#' @param x SafeGraph weekly patterns dataset
#' @return A dataframe containing hourly visits for each weekday
#' @export
get_hourly_visits <- function(x) {
  x <- x %>%
    # select columns related to hourly visits
    select(safegraph_place_id, date_range_start, visits_by_each_hour) %>%
    # Parse visits_by_each_hour [json] into columns in dataframe
    mutate(visits_by_each_hour = str_extract(visits_by_each_hour, "([0-9]+,)+[0-9]")) %>%
    separate(visits_by_each_hour, into = c(str_c("Mon", 1:24, sep = "_"),
                                           str_c("Tue", 1:24, sep = "_"),
                                           str_c("Wed", 1:24, sep = "_"),
                                           str_c("Thu", 1:24, sep = "_"),
                                           str_c("Fri", 1:24, sep = "_"),
                                           str_c("Sat", 1:24, sep = "_"),
                                           str_c("Sun", 1:24, sep = "_")), sep = ",", convert = T) %>%
    # Gather: to make the data tidy
    gather(key = "weekday", value = "visits_by_each_hour", -safegraph_place_id, -date_range_start) %>%
    separate(weekday, into = c("weekday", "hour"), sep = "_", convert = T)
  x
}

#' @title Process daily visits data
#'
#' @description Process all three datasets to get daily visits data by calling function get_daily_visits, bind them together, and take averages
#' @param file_1 SafeGraph weekly patterns dataset (week 1, use read_csv to load)
#' @param file_2 SafeGraph weekly patterns dataset (week 2, use read_csv to load)
#' @param file_3 SafeGraph weekly patterns dataset (week 3, use read_csv to load)
#' @return A dataframe containing average daily visits and average median dwell time for each place of interest (POI)
#' @export
daily_process <- function(file_1 = weekly1, file_2 = weekly2, file_3 = weekly3) {
  temp_daily_processed <- get_daily_visits(file_1) %>%
    # bind three datasets together
    rbind(get_daily_visits(file_2)) %>%
    rbind(get_daily_visits(file_3)) %>%
    # take average of last three weeks
    group_by(safegraph_place_id, weekday) %>%
    summarize(avg_visits = mean(visits_by_day, na.rm = T),
              avg_median_dwell = mean(median_dwell, na.rm = T))
  temp_daily_processed
}


#' @title Process hourly visits data
#'
#' @description Process all three datasets to get hourly visits data by calling function get_hourly_visits, bind them together, and take averages
#' @param file_1 SafeGraph weekly patterns dataset (week 1, use read_csv to load)
#' @param file_2 SafeGraph weekly patterns dataset (week 2, use read_csv to load)
#' @param file_3 SafeGraph weekly patterns dataset (week 3, use read_csv to load)
#' @return A dataframe containing average cv and average peak hourly visits for each place of interest (POI)
#' @export
hourly_process <- function(file_1 = weekly1, file_2 = weekly2, file_3 = weekly3) {
  temp_hourly_processed <- get_hourly_visits(file_1) %>%
    # bind 3 datasets together
    rbind(get_hourly_visits(file_2)) %>%
    rbind(get_hourly_visits(file_3)) %>%
    # calculate cv & peak visits for each week
    group_by(safegraph_place_id, weekday, date_range_start) %>%
    summarise(sd = sd(visits_by_each_hour),
              mean = mean(visits_by_each_hour),
              daily = sum(visits_by_each_hour),
              cv = ifelse(mean == 0 | daily == 1, 0, sd/mean),
              peak = max(visits_by_each_hour)) %>%
    # take average of last three weeks
    group_by(safegraph_place_id, weekday) %>%
    summarise(cv = mean(cv),
              peak = mean(peak))
  temp_hourly_processed
}

#' @title Clean Government Case/Death and Test Data
#' 
#' @description  convert geo_merge to standard names and combine communities repeat as Unincorporated 
#' @param gov_table government case/death or test data downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return cleaned data
#' @import tidyverse
#' @export
clean_gov_data <- function(gov_table){
  gov_table <- gov_table %>% 
    mutate(geo_merge = gsub(
      "(^City of |^Los Angeles - |^Unincorporated - )", "", .$geo_merge)
    ) %>% 
    group_by(geo_merge) %>% 
    summarise_each(sum)
  return(gov_table)
}


#' @title Calculate the Infection Rate
#' 
#' @description Calculate infection rate for each community or the whole region
#' @param rate_original cleaned combined government data downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/ and cleand by clean_gov_data
#' @return A dataframe rate for each community, or a rate for the whole region
#' @import tidyverse
#' @export
calculate_infection_rate <- function(rate_original = rate_original,
                                     each = TRUE) {
  if (each){
    rate <- rate_original %>%
      mutate(infection_rate = 
               (cases_final-deaths_final)/(persons_tested_final-deaths_final)) %>%
      select(geo_merge, infection_rate)
  }
  else{
    rate <- rate_original %>%
      summarise(cases_final = sum(cases_final),
                deaths_final = sum(deaths_final),
                persons_tested_final = sum(persons_tested_final)) %>%
      mutate(infection_rate = (cases_final-deaths_final)/(persons_tested_final-deaths_final))
    rate <- rate$infection_rate
  }
  return(rate)
}


#' @title Match the Infection Rate with POI
#' 
#' @description match infection rate with each POI
#' @param poi_data SafeGraph POI dataset, plus city/community of each POI
#' @param case_death_table The community case and death table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @param testing_table The community testing table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return A dataframe with columns in POI dataset as well as corresponding infection rate for each POI
#' @import tidyverse
#' @importFrom sjmisc str_detect
#' @export
match_infection_rate <- function(poi_data = poi, 
                                 case_death_table = case_death_table,
                                 testing_table = testing_table) {
  # find communities in Log Angeles for future imputaion use
  la_community <- case_death_table %>% 
    select(geo_merge) %>% 
    filter(str_detect(geo_merge, "^Los Angeles")) %>% 
    mutate(geo_merge = gsub(
      "(^City of |^Los Angeles - |^Unincorporated - )", "", .$geo_merge)
    )
  la_community <- la_community$geo_merge
  
  # combine communities repeat as Unincorporated. 
  # convert geo_merge to standard names
  case_death_table <- clean_gov_data(case_death_table)
  testing_table <- clean_gov_data(testing_table)
  # join case/death and test tables 
  rate_original <- testing_table %>% 
    left_join(case_death_table, by = c("geo_merge")) 
  
  # Calculate infection rate for each community
  rate <- calculate_infection_rate(rate_original, each = TRUE)
  # Calculate infection rate for the entire LA county
  rate_LA_county <- calculate_infection_rate(rate_original, each = FALSE)
  # Calculate infection rate for the entire LA city
  rate_LA_city <- rate_original %>%
    filter(geo_merge %in% la_community)
  rate_LA_city <- calculate_infection_rate(rate_LA_city, each = FALSE)
  
  # match cases and infection_rate in rate to poi_data 
  # first match by community names
  poi_data <-  poi_data %>% 
    select(-open_hours_dict) %>% 
    left_join(., rate, by = c("community" = "geo_merge"))
  # then match by city names, los angeles is removed becuase it repeats in rate
  poi_data_other <- poi_data %>% 
    filter(city != "Los Angeles" &
             is.na(poi_data$infection_rate)) %>% 
    select(-infection_rate) %>% 
    left_join(., rate, by = c("city" = "geo_merge"))
  # merge two matched table
  poi_data <- poi_data %>% 
    filter(!is.na(poi_data$infection_rate)|
             city == "Los Angeles") %>% 
    bind_rows(., poi_data_other) 
  
  # Impute rest pois (those that can't find matches) in LA city with the infection rate of LA city
  indexs_la_city <- which(is.na(poi_data$infection_rate) & 
                            poi_data$city == "Los Angeles")
  poi_data$infection_rate[indexs_la_city] <- rate_LA_city 
  
  # Impute rest pois (those that can't find matches) outside LA city with the infection rate of LA county
  indexs_la_county <- which(is.na(poi_data$infection_rate) & 
                              poi_data$city != "Los Angeles")
  poi_data$infection_rate[indexs_la_county] <- rate_LA_county
  
  # return the poi dataset with infection rate for each place
  return(poi_data)
}


#' @title Calculate the risk score
#'
#' @description Calculate the risk score for each POI
#' @param poi SafeGraph POI dataset, plus city/community and infection rate of each POI (the output of function calculate_infection_rate)
#' @param poi_area SafeGraph POI area dataset
#' @param open_hours The dataset containing open hours from Monday to Sunday for each POI
#' @param daily Processed daily visits dataset, output of the function "daily_process"
#' @param hourly Processed houly visits dataset, output of the function "hourly_process"
#' @return The final risk score dataframe
#' @export
calculate_risk_score_poi <- function(poi = poi,
                                     poi_area = poi_area,
                                     open_hours = open_hours,
                                     daily = daily,
                                     hourly = hourly,
                                     density_table = density_table) {
  
  # Joining the data
  risk_poi <- open_hours %>%
    # Join the poi data
    left_join(poi, by = c("safegraph_place_id")) %>% 
    # join poi area_square_feet data
    left_join(poi_area, by = c("safegraph_place_id")) %>% 
    # Join daily visits data
    # For those with open_hours = 0 but still have visitis, adjust the open_hours to median level
    left_join(daily, by = c("safegraph_place_id", "weekday")) %>%
    group_by(weekday) %>%
    mutate(open_hours = ifelse(open_hours == 0 & avg_visits != 0,
                               median(open_hours), open_hours)) %>%
    ungroup() %>%
    # Join the hourly visit data
    left_join(hourly, by = c("safegraph_place_id", "weekday"))
  
  # Calculate the expected number of people encountered when coming to a place
  risk_poi <- risk_poi %>%
    mutate(interval = ifelse(avg_visits == 0, NA, open_hours*60 / avg_visits),
           round_visit = ceiling(avg_visits),
           encounter_max = ifelse(avg_visits == 0, 0,
                                  ceiling(avg_median_dwell / interval)),
           encounter = ifelse(round_visit > encounter_max, encounter_max, round_visit)) %>%
    select(-round_visit, -encounter_max) %>% 
    # Calculate the probability
    # that at least one person that you expect to encounter is/are infectious
    mutate(prob = ifelse(encounter == 0, 0,1-(1-infection_rate)**encounter))
  
  # Calculate risk scores
  risk_poi <- risk_poi %>%
    # Calculate the area per encountered person (+1 to avoid producing Inf)
    mutate(area_per_capita = area_square_feet / (encounter + 1)) %>%
    # Calculate percentile ranks for 3 main attributes:
    # 1. area_per_capita: (reversed) higher value means denser space, greater risk
    # 2. prob: higher value means greater risk
    # 3. hourly distribution (time density): higher value means greater risk
    # The final risk score is the percentile rank of previous three percentile ranks added together
    # Higher value means relatively more risk
    # This is a RELATIVE risk score
    left_join(density_table, by = c("community")) %>% 
    mutate(area_per_capita_perc_rank = 1 - percent_rank(area_per_capita),
           prob_perc_rank = percent_rank(prob),
           cv_perc_rank = percent_rank(cv),
           peak_perc_rank = percent_rank(peak),
           time_density_perc_rank = percent_rank(cv_perc_rank + peak_perc_rank),
           people_density_perc_rank = percent_rank(Density),
           risk_score = percent_rank(area_per_capita_perc_rank + prob_perc_rank + time_density_perc_rank + people_density_perc_rank))
  
  
  # Reorder columns, add risk level and update date
  # NA: -1
  breaks <- quantile(risk_poi$risk_score, probs = c(0.25, 0.5, 0.75),na.rm = TRUE)
  risk_poi <- risk_poi %>%
    mutate(risk_level = ifelse(is.na(risk_score), 0, 
                               ifelse(risk_score <= breaks[1], 1,
                                      ifelse(risk_score <= breaks[2], 2,
                                             ifelse(risk_score <= breaks[3], 3, 4))))) %>% 
    select(safegraph_place_id, weekday, location_name, top_category, 
           latitude, longitude, street_address, postal_code, 
           city, community,
           risk_score, risk_level)
  # Return the final risk scores
  return(risk_poi)
}

calculate_risk_score_community <- function(risk_poi){
  risk_community <- risk_poi %>% 
    group_by(community,weekday) %>% 
    summarise(risk_score = mean(risk_score,na.rm = TRUE))
  
  breaks <- quantile(risk_community$risk_score, probs = c(0.25, 0.5, 0.75),na.rm = TRUE)
  risk_community <- risk_community %>%
    mutate(risk_level = ifelse(is.na(risk_score), 0, 
                               ifelse(risk_score <= breaks[1], 1,
                                      ifelse(risk_score <= breaks[2], 2,
                                             ifelse(risk_score <= breaks[3], 3, 4)))))
  return(risk_community)
}

#' @title Weekday to date
#' 
#' @description convert weekday to date and add cases_final by joining case_death_table
#' @param risk the final risk score dataframe
#' @param update_date the update date of SafeGraph data
#' @param case_death_table the community case and death table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return the final risk score dataframe 
#' @import tidyverse
#' @export
weekday_match <- function(risk, case_death_table, new_update_date){
  risk <- risk %>% 
    filter(weekday == new_update_date) %>% 
    mutate(risk_score = ifelse(is.na(risk_score), 0, risk_score),
           day = new_update_date) %>%
    left_join((clean_gov_data(case_death_table) %>% 
                 select(geo_merge, cases_final)),
              by = c("community" = "geo_merge")) %>% 
    select(-weekday)
  return(risk)
}


#' @title Calculate the risk score, an integrated solution
#'
#' @description An integrated solution, combining all functions in one step to calculate the risk score for each POI
#' @param file_1 SafeGraph weekly patterns dataset (week 1, use read_csv to load)
#' @param file_2 SafeGraph weekly patterns dataset (week 2, use read_csv to load)
#' @param file_3 SafeGraph weekly patterns dataset (week 3, use read_csv to load)
#' @param poi SafeGraph POI dataset
#' @param poi_area SafeGraph POI area dataset
#' @param open_hours The dataset containing open hours from Monday to Sunday for each POI
#' @param case_death_table The community case and death table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @param testing_table The community testing table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return The final risk score dataframe
#' @export
risk_score <- function(file_1, file_2, file_3,
                       poi, poi_area, open_hours,
                       case_death_table, testing_table, density_table) {
  print("Start calculating risk score")
  print("Processing daily visits data... may take a few minutes")
  daily <- daily_process(file_1, file_2, file_3)
  print("Processing hourly visits data... may take a few minutes")
  hourly <- hourly_process(file_1, file_2, file_3)
  print("Calculating infection rate and matching each POI with corresponding infection rate")
  poi_extended <- match_infection_rate(poi, case_death_table, testing_table)
  print("Calculating poi risk scores")
  risk_poi <- calculate_risk_score_poi(poi_extended, poi_area, open_hours, daily, hourly, density_table)
  print("Calculating community risk scores")
  risk_community <- calculate_risk_score_community(risk_poi)
  print("Complete calculation!")
  risk <- list('risk_poi' = risk_poi, 'risk_community' = risk_community)
  return(risk)
}


# load data ---------------------------------------------------------------

print('start loading required data')
poi <- read_csv('data/processed/RMDS_poi.csv', col_types = cols())
poi_area <- read_csv('data/processed/RMDS_poi_area_square_feet.csv', col_types = cols())
open_hours <- read_csv('data/processed/RMDS_open_hours.csv', col_types = cols())
case_death_table <- read_csv('data/external/LA_County_Covid19_CSA_case_death_table.csv', col_types = cols())
testing_table <- read_csv('data/external/LA_County_Covid19_CSA_testing_table.csv', col_types = cols())
density_table <- read_csv('data/raw/Covid-19-density.csv', col_types = cols())
file_1_clean <- read_csv('data/processed/pattern-0812.csv', col_types = cols())
file_2_clean <- read_csv('data/processed/pattern-0819.csv', col_types = cols())
file_3_clean <- read_csv('data/processed/pattern-0826.csv', col_types = cols())
print('finish loading required data')

# calculate risk score ----------------------------------------------------
new_update_date <- substring(weekdays(Sys.Date()), 1, 3)

density_table <- density_table %>% 
  mutate(Timestamp = as.Date(`Time Stamp`, format="%m-%d-%y")) %>% 
  filter(Timestamp == max(Timestamp)) %>% 
  select(Region, Density) %>% 
  transmute(community = Region, Density = Density)


risk <- risk_score(file_1_clean, file_2_clean, file_3_clean,
                   poi, poi_area, open_hours,
                   case_death_table, testing_table, density_table) 

# match with the weekday to make calculation
risk_poi <- weekday_match(risk$risk_poi, case_death_table, new_update_date) %>% select(-day)
risk_community <- weekday_match(risk$risk_community, case_death_table, new_update_date) %>% 
  select(community,risk_score, risk_level)

print('Saving risk scores to files')
write_csv(risk_poi ,paste0('data/risk_latest/risk_poi-',toString(Sys.Date()),'.csv'))
write_csv(risk_community ,paste0('data/risk_latest/risk_community-',toString(Sys.Date()),'.csv'))
print("Completed!")
