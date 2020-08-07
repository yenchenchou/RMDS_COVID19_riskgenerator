"""
@author: Yen-Chen Chou
"""
import glob
import os

import pandas as pd

class WeekPattern:
    def __init__(self, folder_path, week_str):
        self.week_str = week_str
        self.folder_path = folder_path
        self.df_pattern = pd.DataFrame()
        self.path_list = list()


    def get_pattern(self):
        """"""
        self.get_paths()
        for path in self.path_list:
            df_tmp = pd.read_csv(
                path, 
                usecols= ["safegraph_place_id",
                          "visits_by_day",
                          "visits_by_each_hour",
                          "median_dwell",
                          "date_range_start"],
                compression="gzip")
            self.df_pattern = pd.concat(
                [self.df_pattern, df_tmp],
                axis=0,
                ignore_index=True)
        return self.df_pattern


    def get_paths(self):
        """"""
        all_paths = glob.glob(os.path.join(self.folder_path, "*.csv.gz"))
        # print(all_paths)
        for path in all_paths:
            if self.week_str in path:
                self.path_list.append(path)
        self.path_list.sort()