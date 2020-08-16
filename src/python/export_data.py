"""
@author: Yen-Chen Chou
"""
import os
import sys

import pandas as pd

from covid_case_getter import WebCsvDownload
from core_poi_getter import POI
from postal_community_mapper import ZipCommunityMapper
from poi_area_getter import POIArea
from open_store_getter import OpenHour
from weekly_pattern_getter import WeekPattern



if __name__ == "__main__":
    
    WEEK1 = sys.argv[1]
    WEEK2 = sys.argv[2]
    WEEK3 = sys.argv[3]
    CASE_URL = "https://lacdph.shinyapps.io/"\
        "covid19_surveillance_dashboard/_w_fc870600"\
        "/session/6a3aec46f8bffc24c77848c9177e8c32/download/download2?w=fc870600"
    TEST_URL = "https://lacdph.shinyapps.io/"\
        "covid19_surveillance_dashboard/_w_8a7ea990"\
            "/session/305b5feaaba1a6cd7fdd90b02b0ce8b9/download/download4?w=8a7ea990"


    if os.path.isfile("data/internal/RMDS_zipcode_mapper.json"):
        print("RMDS_zipcode_mapper.json already exists")
        print("\n")
    else:
        print("Starting scraping data from .laalmanac.com...")
        REF_FILE_PATH = "data/external/LA_County_Covid19_CSA_testing_table.csv"
        URL = "http://www.laalmanac.com/communications/cm02_communities.php"
        zip_community_mapper = ZipCommunityMapper(REF_FILE_PATH, URL)
        print("Starting getting data mapper...")
        map_table = zip_community_mapper.get_mapper()
        zip_community_mapper.save_json()
        print("Complete saving zipcode_mapper!")
        print("\n")


    print("Start getting LA County COVID-19 cases and death data...")
    case_crawler = WebCsvDownload(CASE_URL)
    test_crawler = WebCsvDownload(TEST_URL)
    case_crawler.save_csv()
    test_crawler.save_csv()
    print("Complete saving LA County COVID-19 cases and death data!")
    print("\n")


    print("Start getting poi data...")
    FOLDER_PATH = "data/external/Core-USA-August2020-Release"\
        "-CORE_POI-2020_07-2020-08-07"
    poi_getter = POI(FOLDER_PATH)
    print("Getting core POI data, it may take up to 1 min...")
    poi_getter.read_mapper()
    df_poi = poi_getter.get_poi()
    df_poi.to_csv("data/processed/RMDS_poi.csv", index=False)
    del df_poi
    print("Complete saving poi data!")
    print("\n")


    print("Start getting poi area data...")
    area_getter = POIArea()
    df_area = area_getter.get_area()
    df_area.to_csv("data/processed/RMDS_poi_area_square_feet.csv", index=False)
    del df_area
    print("Complete saving poi area data!")
    print("\n")


    print("Start getting open hours data...")
    FILE_PATH = "data/processed/RMDS_poi.csv"
    open_hours = OpenHour(FILE_PATH)
    print("Getting hour data, it may take up to 2 mins...")
    open_hours.read_data()
    open_hours_df = open_hours.get_open_hours()
    open_hours_df.to_csv("data/processed/RMDS_open_hours.csv", index=False)
    del open_hours_df
    print("Complete saving open hours data!")
    print("\n")

    print("Start getting weekly pattern data...")
    FOLDER_PATH = "data/external/weekly_pattern"
    # week_pattern = WeekPattern(FOLDER_PATH, "0710", "0722", "0729")
    print("Getting hour data, it may take up to 5 mins...")
    week_pattern = WeekPattern(FOLDER_PATH, WEEK1, WEEK2, WEEK3)
    week_pattern.check_availability()
    week_pattern.get_all_pattern()
    print("Complete saving weekly pattern data!")


