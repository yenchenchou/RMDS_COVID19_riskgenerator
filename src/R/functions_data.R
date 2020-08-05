library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(sjmisc)
library(roxygen2)
library(devtools)


#' @title preclean SafeGraph weekly pattern data
#' 
#' @description select only useful columns for risk score calcultation and points in CA
#' @import dplyr
#' @param sg_data SafeGraph weekly pattern data downloaded from https://catalog.safegraph.io/app/information
#' @param poi SafeGraph POI dataset (only contain CA data)
sg_data_cleaning <- function(sg_data, poi){
  sg_data <- sg_data %>% 
    select(safegraph_place_id, 
           visits_by_day, 
           visits_by_each_hour, 
           median_dwell, 
           date_range_start) 
  # inner join to filter points only in CA
  sg_data <- sg_data %>% 
    merge(poi %>% select(safegraph_place_id), 
          by = "safegraph_place_id")
  return(sg_data)
}


#' @title Get Government Case/Death and Test Data
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

