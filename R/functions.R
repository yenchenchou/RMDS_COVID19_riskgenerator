library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(sjmisc)
library(roxygen2)
library(devtools)

#' @title Get Daily Visits
#'
#' @description This function allows you to get information related to daily visits from SafeGraph weekly patterns dataset
#' @param x SafeGraph weekly patterns dataset
#' @return A dataframe containing daily visits for each weekday
#' @export
get_daily_visits <- function (x) {
  # select daily visit data
  temp_daily <- x %>%
    # select columns related to daily visits
    select(safegraph_place_id, date_range_start, date_range_end, visits_by_day, median_dwell) %>%
    # Parse visits_by_day [json] into columns in dataframe
    # Each represents a weekday: from Monday to Sunday
    mutate(visits_by_day = str_extract(visits_by_day, "([0-9]+,)+[0-9]")) %>%
    separate(visits_by_day, into = c("Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"),
             sep = ",", convert = T) %>%
    # Gather: to make the data tidy
    gather(key = "weekday", value = "visits_by_day", -safegraph_place_id, -date_range_start, -date_range_end, -median_dwell)
  temp_daily
}

#' @title Get hourly visits
#'
#' @description This function allows you to get information related to hourly visits from SafeGraph weekly patterns dataset
#' @param x SafeGraph weekly patterns dataset
#' @return A dataframe containing hourly visits for each weekday
#' @export
get_hourly_visits <- function(x) {
  temp_hourly <- x %>%
    # select columns related to hourly visits
    select(safegraph_place_id, date_range_start, date_range_end, visits_by_each_hour) %>%
    # Parse visits_by_each_hour [json] into columns in dataframe
    mutate(visits_by_each_hour = str_extract(visits_by_each_hour, "([0-9]+,)+[0-9]")) %>%
    separate(visits_by_each_hour, into = c(str_c("Mon", 1:24, sep = "_"),
                                           str_c("Tue", 1:24, sep = "_"),
                                           str_c("Wed", 1:24, sep = "_"),
                                           str_c("Thur", 1:24, sep = "_"),
                                           str_c("Fri", 1:24, sep = "_"),
                                           str_c("Sat", 1:24, sep = "_"),
                                           str_c("Sun", 1:24, sep = "_")), sep = ",", convert = T) %>%
    # Gather: to make the data tidy
    gather(key = "weekday", value = "visits_by_each_hour", -safegraph_place_id, -date_range_start, -date_range_end) %>%
    separate(weekday, into = c("weekday", "hour"), sep = "_", convert = T)
  temp_hourly
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


#' @title Calculate the Infection Rate
#' 
#' @description Calculate infection rate for each community, and then match them with each POI
#' @param poi_data SafeGraph POI dataset, plus city/community of each POI
#' @param case_death_table The community case and death table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @param testing_table The community testing table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return A dataframe with columns in POI dataset as well as corresponding infection rate for each POI
#' @import tidyverse
#' @importFrom sjmisc str_detect
#' @export
calculate_infection_rate <- function(poi_data = poi, 
                                     case_death_table = case_death_table,
                                     testing_table = testing_table) {
  
  # Calculate infection rate for each community
  rate_original <- case_death_table %>% 
    left_join(testing_table, by = c("geo_merge")) 
  
  rate <- rate_original %>%
    mutate(infection_rate = (cases_final-deaths_final)/(persons_tested_final-deaths_final)) %>%
    select(geo_merge, infection_rate)
  
  # Calculate infection rate for the entire LA city
  rate_LA <- rate_original %>%
    filter(str_detect(geo_merge, "^Los Angeles")) %>%
    summarise(cases_final = sum(cases_final),
              deaths_final = sum(deaths_final),
              persons_tested_final = sum(persons_tested_final)) %>%
    mutate(infection_rate = (cases_final-deaths_final)/(persons_tested_final-deaths_final))
  rate_LA <- rate_LA$infection_rate
  
  # change place names to lowercase for matching
  # 'angeles national forest','del rey','florence-firestone','harbor gateway' 
  # repeat in Los Angeles and Unincorporated . Treat them in Los Angeles
  poi_data <- poi_data %>% mutate('city_lower' = tolower(poi_data$city),
                                  'community_lower' = tolower(poi_data$community))
  rate <- rate %>% mutate('geo_merge_lower' = tolower(rate$geo_merge)) %>% 
    separate(.,col = geo_merge_lower,
             c('city_lower','community_lower'),sep=" - ", remove = FALSE) %>% 
    filter(!(community_lower %in% c('angeles national forest', 
                                    'del rey', 
                                    'florence-firestone',
                                    'harbor gateway') & 
               city_lower == 'unincorporated'))
  
  # match infection_rate in rate to poi_data 
  # first match by community names
  poi_data <-  poi_data %>% left_join(.,
                                      subset(rate, select = c(infection_rate,community_lower)), 
                                      by = 'community_lower') 
  # then match by city names, los angeles is removed becuase it repeats in rate
  poi_data_other <- poi_data %>% filter(city_lower != "los angeles" &
                                          is.na(poi_data$infection_rate)) %>% 
    select(-infection_rate) %>% 
    left_join(.,
              subset(rate, select = c(infection_rate,city_lower)), 
              by = 'city_lower')
  # merge two matched table
  poi_data <- poi_data %>% 
    filter(!is.na(poi_data$infection_rate)|
             city_lower == "los angeles") %>% 
    bind_rows(., poi_data_other) %>% 
    select(-c(city_lower,community_lower))
  
  # Impute rest pois (those that can't find matches) with the infection rate of LA city
  poi_data <- poi_data %>%
    mutate(infection_rate = ifelse(is.na(infection_rate), rate_LA, infection_rate))
  
  # return the poi dataset with infection rate for each place
  poi_data
}


#' @title get Government Case/Death and Test Data
#' 
#' @description download and save case/death and test cvs from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' To check chrome version: binman::list_versions("chromedriver")
#' @import RSelenium
#' @param chromever chrome version
#' @param path save path, default is in Data folder
#' @export
# library(RSelenium)
get_gov_data_rpi <- function(chromever, path = './Data'){
  
  rd <- rsDriver(browser = c("chrome"),chromever = chromever)
  remDr <- rd$client
  
  gov_url <- 'http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/'
  # navigate to main page
  remDr$navigate(gov_url)
  Sys.sleep(3) # wait until the page stop  loading
  
  frames <- remDr$findElements("css", "iframe")
  remDr$switchToFrame(frames[[1]])
  
  # find the case_death box and click
  webElem_side1 <- remDr$findElement(using = 'xpath',
                                     value = "//html/body/div/aside/section/ul/li[4]")
  webElem_side1$clickElement()
  Sys.sleep(8) # wait until the page stop  loading
  webElem_side1$clickElement()
  
  # find download box
  webElem_table1 <- remDr$findElement(using = 'xpath',
                                      value = "//html/body/div/div/section/div/div[@class ='tab-pane active']/div/div/div/div[@class = 'box-body']/a")
  
  # get link
  url_table1 <- webElem_table1$getElementAttribute('href')
  # download case_death file
  download.file(url_table1[[1]],
                paste0(path,'/LA_County_Covid19_CSA_case_death_table.csv'))
  
  
  # find the testing box and click
  webElem_side2 <- remDr$findElement(using = 'xpath',
                                     value = "//html/body/div/aside/section/ul/li[5]")
  webElem_side2$clickElement()
  Sys.sleep(3) # wait until the page stop  loading
  webElem_side1$clickElement()
  
  # find download box
  webElem_table2 <- remDr$findElement(using = 'xpath',
                                      value = "//html/body/div/div/section/div/div[@class ='tab-pane active']/div/div/div/div[@class = 'box-body']/a")
  
  
  # get link
  url_table2 <- webElem_table2$getElementAttribute('href')
  # download case_death file
  download.file(url_table2[[1]], 
                paste0(path,'/LA_County_Covid19_CSA_testing_table.csv'))
  remDr$closeServer()
  remDr$close()
  rd$server$stop()
  return(print(paste0("Success. Files are stored.")))
}


#' @title Calculate the risk score
#'
#' @description Calculate the risk score for each POI
#' @param poi SafeGraph POI dataset, plus city/community and infection rate of each POI (the output of function calculate_infection_rate)
#' @param open_hours The dataset containing open hours from Monday to Sunday for each POI
#' @param daily Processed daily visits dataset, output of the function "daily_process"
#' @param hourly Processed houly visits dataset, output of the function "hourly_process"
#' @return The final risk score dataframe
#' @export
calculate_risk_score <- function(poi = poi,
                                 open_hours = open_hours,
                                 daily = daily,
                                 hourly = hourly) {
  
  # Joining the data
  risk <- open_hours %>%
    # Join the poi data
    left_join(poi %>% select(safegraph_place_id, location_name, top_category, latitude, longitude, street_address, city, community, postal_code, area_square_feet, infection_rate),
              by = c("safegraph_place_id")) %>%
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
  risk <- risk %>%
    mutate(interval = ifelse(avg_visits == 0, NaN, open_hours*60 / avg_visits),
           round_visit = ceiling(avg_visits),
           encounter_max = ifelse(avg_visits == 0, 0,
                                  ceiling(avg_median_dwell / interval)),
           encounter = ifelse(round_visit > encounter_max, encounter_max, round_visit)) %>%
    select(-round_visit, -encounter_max)
  
  # Calculate the probability
  # that at least one person that you expect to encounter is/are infectious
  prob <- double()
  for (i in 1:nrow(risk)) {
    size <- risk$encounter[i]
    p <- risk$infection_rate[i]
    prob[i] <- ifelse(size == 0, 0,
                      sum(dbinom(1:size, size, p)))
  }
  
  # Add to the risk table
  risk$prob <- prob
  
  # Calculate risk scores
  risk <- risk %>%
    # Calculate the area per encountered person (+1 to avoid producing Inf)
    mutate(area_per_capita = area_square_feet / (encounter + 1)) %>%
    # Calculate percentile ranks for 3 main attributes:
    # 1. area_per_capita: (reversed) higher value means denser space, greater risk
    # 2. prob: higher value means greater risk
    # 3. hourly distribution (time density): higher value means greater risk
    # The final risk score is the percentile rank of previous three percentile ranks added together
    # Higher value means relatively more risk
    # This is a RELATIVE risk score
    mutate(area_per_capita_perc_rank = 1 - percent_rank(area_per_capita),
           prob_perc_rank = percent_rank(prob),
           cv_perc_rank = percent_rank(cv),
           peak_perc_rank = percent_rank(peak),
           time_density_perc_rank = percent_rank(cv_perc_rank + peak_perc_rank),
           risk_score = percent_rank(area_per_capita_perc_rank + prob_perc_rank + time_density_perc_rank))
  
  # Reorder columns, add risk level and update date
  # NA: -1
  risk <- risk %>%
    mutate(risk_level = ifelse(is.na(risk_score), -1,
                               ifelse(risk_score <= 0.1, 0,
                                      ifelse(risk_score <= 0.5, 1,
                                             ifelse(risk_score <= 0.9, 2, 3)))),
           risk_score = ifelse(is.na(risk_score), -1, risk_score),
           update_date = Sys.Date()) %>%
    select(safegraph_place_id, location_name, top_category, latitude, longitude, street_address, postal_code, city, community, everything())
  
  # Return the final risk scores
  risk
}

#' @title Calculate the risk score, an integrated solution
#'
#' @description An integrated solution, combining all functions in one step to calculate the risk score for each POI
#' @param file_1 SafeGraph weekly patterns dataset (week 1, use read_csv to load)
#' @param file_2 SafeGraph weekly patterns dataset (week 2, use read_csv to load)
#' @param file_3 SafeGraph weekly patterns dataset (week 3, use read_csv to load)
#' @param poi SafeGraph POI dataset, plus city/community and infection rate of each POI (the output of function calculate_infection_rate)
#' @param open_hours The dataset containing open hours from Monday to Sunday for each POI
#' @param case_death_table The community case and death table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @param testing_table The community testing table downloaded from http://dashboard.publichealth.lacounty.gov/covid19_surveillance_dashboard/
#' @return The final risk score dataframe
#' @export
main <- function(file_1, file_2, file_3,
                 poi, open_hours,
                 case_death_table, testing_table) {
  print("Processing daily visits data")
  daily <- daily_process(file_1, file_2, file_3)
  print("Processing hourly visits data")
  hourly <- hourly_process(file_1, file_2, file_3)
  print("Calculating infection rate and matching each POI with corresponding infection rate")
  poi_extended <- calculate_infection_rate(poi, case_death_table, testing_table)
  print("Calculating risk scores")
  risk <- calculate_risk_score(poi_extended, open_hours, daily, hourly)
  print("Completed")
  return(risk)
}

#devtools::document()
