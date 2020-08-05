"""
@author: Yen-Chen Chou
"""
import json
import os
import re
import time

import bs4
import numpy as np
import pandas as pd
import requests

from collections import defaultdict
from datetime import datetime

from core_poi_getter import POI
from postal_community_mapper import ZipCommunityMapper
from poi_area_getter import POIArea
from open_store_getter import OpenHour


if __name__ == "__main__":
    if os.path.isfile("data/internal/RMDS_zipcode_mapper.json"):
        print("RMDS_zipcode_mapper.json already exists")
        print("\n")
    else:
        print("Starting scraping data from .laalmanac.com...")
        url = "http://www.laalmanac.com/communications/cm02_communities.php"
        zip_community_mapper = ZipCommunityMapper()
        zip_community_mapper._get_postal_community(url)
        print("Starting getting data mapper...")
        map_table = zip_community_mapper.get_mapper(url)
        zip_community_mapper.save_json()
        print("Complete saving zipcode_mapper!")
        print("\n")


    print("Start getting poi data...")
    poi_getter = POI()
    poi_getter.read_mapper()
    df_poi = poi_getter.get_poi()
    df_poi.to_csv("data/processed/RMDS_poi.csv", index = False)
    print("Complete saving poi data!")
    print("\n")


    print("Start getting poi area data...")
    area_getter = POIArea()
    df_area = area_getter.get_area()
    df_area.to_csv("data/processed/RMDS_poi_area_square_feet.csv", index = False) # csv.gz
    print("Complete saving poi area data!")
    print("\n")


    print("Start getting open hours data...")
    file_path = "data/external/Core-USA-July2020-Release-CORE_POI-2020_06-2020-07-13/core_poi-part1.csv.gz"
    open_hours = OpenHour(file_path)
    open_hours.read_data()
    print("getting hour data, it may take up to 2 mins...")
    open_hours_df = open_hours.get_open_hours_df()
    open_hours_df.to_csv("data/processed/RMDS_open_hours.csv", index = False)
    print("Complete saving open hours data!")

