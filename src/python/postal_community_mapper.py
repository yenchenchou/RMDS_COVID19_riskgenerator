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

# os.chdir("/Users/yenchenchou/Documents/RMDS_YC/RiskScore/RMDS_COVID19_riskgenerator")

class ZipCommunityMapper(object):
    
    def __init__(self):
        self.obj = None
        self.community_ls = list()
        self.zipcode_ls = list()
        self.com_zip_dict = defaultdict(set)
        self.final_dict = dict()
    
       
    def _get_reference_community(self):
        reference_com = []
        community_names = pd.read_csv(
            "data/external/LA_County_Covid19_CSA_testing_table.csv",
            usecols = ["geo_merge"])
        
        for val in community_names["geo_merge"]:
            new_val = re.sub(
                "(^City.of.|Los Angeles - |Unincorporated - )", "", val)
            reference_com.append(new_val)
        return reference_com
        
        
    def _get_url_connect(self, url):
        try:
            url = url
            self.obj = requests.get(url)
        except:
            if self.obj.status_code >= 400 and self.obj.status_codeatus_code <= 499:
                raise Exception("Client Error")
            elif self.obj.status_code >= 500 and self.obj.status_codeatus_code <= 599:
                raise Exception("Server Error")
            else:
                raise Exception("Not Client or Server Error, please update the code")


    def _get_postal_community(self, url):
        self._get_url_connect(url)
        web_content = bs4.BeautifulSoup(self.obj.text, "html.parser")
        table = web_content.find_all("td")
        for idx in range(len(table)):
            if idx % 2 == 0:
                community = table[idx].text.strip()
                self.community_ls.append(community)
            else:
                zipcode = table[idx].text.split("(")[0].strip()
                self.zipcode_ls.append(zipcode)


    def _clean_community(self):
        reference_com = self._get_reference_community()
        new_community_ls = list()
        for val in self.community_ls:
            v = re.sub(r"(^Los.Angeles.|\(Los Angeles\)|PO Boxes|\/.*)", "", val.strip())
            v = re.sub(r"(^Pasadena.*)", "Pasadena", v)
            v = re.sub(r"(^Alhambra.*)", "Alhambra", v)
            v = re.sub(r"(^Downtown.*)", "Downtown", v)
            v = re.sub(r"(.*Long Beach.*)", "Long Beach", v)
            v = re.sub(r"(Santa Clarita )", "", v)
            v = re.sub(r"(\(|\))", "", v.strip())
            new_community_ls.append(v)

        ls = list()
        for val in new_community_ls:
            for ref in reference_com:
                if ref in val:
                    ls.append(ref)
                    break
            else:
                ls.append("missing")
        self.community_ls = ls

        
    def _clean_postal(self):
        new_zipcode_ls = list()
        for zip_sublist in self.zipcode_ls:
            tmp_list = [int(zipcode.strip()) for zipcode in zip_sublist.split(",")]
            new_zipcode_ls.append(tmp_list)
        self.zipcode_ls = new_zipcode_ls
        
        
    def _init_mapper(self):
        for i in range(len(self.community_ls)):
            community = self.community_ls[i]
            zip_sub_ls = self.zipcode_ls[i]
            for zipcode in zip_sub_ls:
                self.com_zip_dict[zipcode].add(community)

                    
    def _clean_mapper(self):
        map_table = dict()
        for key, val in self.com_zip_dict.items():
            map_table[key] = list(val)
        self.com_zip_dict = map_table
        
        for key, val in map_table.items():
            if "missing" in val and len(val) > 1:
                val.remove("missing")

        self.com_zip_dict = map_table
    
    
    def _correct_mapper(self):
        with open("data/external/zipcode_correction.json") as json_file:
            correction_data = json.load(json_file)
        
        for key, val in self.com_zip_dict.items():
            try:
                self.final_dict[key] = correction_data[str(key)]
            except:
                self.final_dict[key] = val[0]

    
    def get_mapper(self, url):  
        
        self._get_postal_community(url)
        self._clean_postal()
        self._clean_community()
        self._init_mapper()
        self._clean_mapper()
        self._correct_mapper()
        
        return self.final_dict

    def save_json(self):
        with open("data/internal/RMDS_zipcode_mapper.json", "w") as file:
            json.dump(self.final_dict, file)
        print("Data Saved!")


# if __name__ == "__main__":
#     print("Starting getting data from .laalmanac.com...")
#     url = "http://www.laalmanac.com/communications/cm02_communities.php"
#     zip_community_mapper = ZipCommunityMapper()
#     zip_community_mapper._get_postal_community(url)
#     print("Starting getting data mapper...")
#     map_table = zip_community_mapper.get_mapper(url)
#     zip_community_mapper.save_json()
#     print("Complete!")