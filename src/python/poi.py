"""
Created on Thu Jul 29 22:40:15 2020
@author: Yen-Chen Chou
"""

import os
import time

import bs4
import numpy as np
import pandas as pd
import requests

from geopy.geocoders import Nominatim

df = pd.read_csv("data/poi_extended.csv")


def get_community_list():
    
    url = "https://media.ocgov.com/about/infooc/links/oc/occities.asp"
    obj = requests.get(url)
    web_content = bs4.BeautifulSoup(obj.text, "html.parser")
    target_content = web_content.find_all("a", {"class":"catch-external"})
    orange_county_comm = \
        [row.get_text().replace("City of ", "") for row in target_content]
    orange_county_comm.append("Orange County")
    
    return orange_county_comm


def exclude_community(df):
    
    idx_list = []
    for idx in range(len(df)):
        if df.iloc[idx]["city"] in orange_county_comm:
            idx_list.append(idx)
    df.drop(df.index[idx_list], inplace = True)
    
    return df


def get_address():
    geolocator = Nominatim(user_agent = "POI_city_finder", timeout = 500)
    la_community_list = list(df["city"].sort_values().unique())
    city_series = df.loc[df["city"] == "Los Angeles County", :]
    location_list, location_list_new = [], []
    for idx in city_series.index:
        address = list(df[["street_address", "city_original"]].iloc[idx])
        address = ", ".join(address)
        location = geolocator.geocode(address) 
        if location is None:
            address2 = list(df[["location_name", "street_address", "postal_code"]].iloc[idx].astype("str"))
            address2 = ", ".join(address2)
            location = geolocator.geocode(address2) 
            try:
                location = location[0]
            except TypeError:
                location = "missing"      

        location_list.append(location)
    return location_list, la_community_list


def match_community(location, la_community_list):
    
    for community in la_community_list:
        if community in location[0]:
            return community
    else:
        return "missing"
    
    
def get_community():
    
    location_list, la_community_list = get_address()
    location_list_new = []    
    for location in location_list:  
        community = match_community(location, la_community_list)
        location_list_new.append(community)     

    return location_list_new


def replace_value(df):
    
    city_series = df.loc[df["city"] == "Los Angeles County", "community"]
    df["community"].replace({"Downtown": "Los Angeles"}, inplace = True)
    df.loc[df["city"] == "Los Angeles County", "community"] = get_community()
    df.loc[df["city"] == "Los Angeles County", "city"] = city_series
    
    return df


if __name__ == "__main__":
    print("Starting cleaning data...")
    orange_county_comm = get_community_list()
    df = exclude_community(df)
    print("Excluded out of scope communities...")
    df = replace_value(df)
    print("Cleaning typo...")
    df.to_csv("data/RMDS_poi_extended.csv")
    print("Complete!")
