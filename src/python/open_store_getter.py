"""
@author: Yen-Chen Chou
"""
import ast
import json
import os
import re
import time

import pandas as pd

from collections import defaultdict
from datetime import datetime


class OpenHour(object):

    def __init__(self, file_path):
        self.df = None
        self.file_path = file_path


    def read_data(self):
        self.df = pd.read_csv(
            self.file_path,
            compression="gzip",
            usecols = [
                'safegraph_place_id', 
                'open_hours'])
        self.df = self.df[self.df["open_hours"].notnull()].copy()


    def _turn_dict_helper(self, x): 
        try:
            return ast.literal_eval(x)
        except:
            empty_time = {
                "Mon":[],
                "Tue":[],
                "Wed":[],
                "Thur":[],
                "Fri":[],
                "Sat":[],
                "Sun":[]
            }
            return empty_time


    def turn_dict(self):
        self.df["open_hours"] = self.df["open_hours"].apply(lambda x: self._turn_dict_helper(x))
        return self.df


    def _tstrp(self, t):
        h, m  = t.split(":")
        if int(h) > 23:
            t = "0:00"
        return datetime.strptime(t,"%H:%M")


    def _get_hours_period(self, val_list):
        
        max_hours = 0
        if len(val_list) == 0:
            return 0
        else:
            for val in val_list:
                open_t, close_t = self._tstrp(val[0]), self._tstrp(val[1])
                hours = (close_t - open_t).seconds / 3600
                if hours < 0:
                    hours = 24 + hours
                if hours > max_hours:
                    max_hours = hours
            return max_hours

            
    def get_open_hours_df(self):

        
        self.df = self.turn_dict()
        open_hours_ls = list()

        for row in self.df.iterrows():
            place_id, open_hours = row[1][0], row[1][1]
            for key, val_list in open_hours.items():
                day = open_hours
                hours = self._get_hours_period(val_list)
                row = (place_id, key, hours)
                open_hours_ls.append(row)

        self.df = pd.DataFrame(
                open_hours_ls, 
            columns = [
                "safegraph_place_id", 
                "weekday",
                "open_hours"])

        return self.df   


# if __name__ == "__main__":
#     file_path = "data/external/Core-USA-July2020-Release-CORE_POI-2020_06-2020-07-13/core_poi-part1.csv.gz"
#     open_hours = OpenHour(file_path)
#     print("read initial data...")
#     open_hours.read_data()
#     print("getting hour data, it may take up to 2 mins...")
#     open_hours_df = open_hours.get_open_hours_df()
#     print("saving...")
#     open_hours_df.to_csv("data/processed/open_hours.csv", index = False)
#     print("complete!")