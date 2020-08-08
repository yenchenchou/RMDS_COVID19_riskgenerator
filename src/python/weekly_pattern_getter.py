"""
@author: Yen-Chen Chou
"""
#%%
import glob
import os
from pathlib import Path

import pandas as pd

from _file_display import DisplayablePath

class WeekPattern():
    def __init__(self, folder_path, week1, week2, week3):
        self.week1 = week1
        self.week2 = week2
        self.week3 = week3
        self.folder_path = folder_path
        self.df_pattern = pd.DataFrame()
        self.df_poi = pd.read_csv("data/processed/RMDS_poi.csv")
        self.folder_names = list()
        self.paths = None


    def see_available_files(self, silent=True):
        self.paths = DisplayablePath.make_tree(Path(self.folder_path))
        if silent:
            pass
        else:
            for path in self.paths:
                print(path.displayable())


    def get_all_pattern(self):
        self.get_folders()
        for folder in self.folder_names:
            file_list = self.get_file_paths(folder)
            self.df_pattern = self.get_one_pattern(file_list)
            file_save_path = "data/processed/pattern-" + folder[-4:]
            self.df_pattern.to_csv(file_save_path+".csv", index=False)
            self.df_pattern = None
            print(file_save_path, "saved!")


    def get_one_pattern(self, file_list):
        """"""
        for path in file_list:
            df_filter = self.get_filter(path)
            self.df_pattern = pd.concat(
                [self.df_pattern, df_filter],
                axis=0,
                ignore_index=True)
        return self.df_pattern


    def get_filter(self, path):
        df_tmp = pd.read_csv(
            path, 
            usecols= ["safegraph_place_id",
                      "visits_by_day",
                      "visits_by_each_hour",
                      "median_dwell",
                      "date_range_start",
                      "date_range_end"],
            compression="gzip")
        df_tmp = pd.merge(df_tmp, self.df_poi, how="inner")
        return df_tmp


    def get_folders(self):
        weeks = [self.week1, self.week2, self.week3]
        for week in weeks:
            self.folder_names.append(os.path.join(self.folder_path, week))


    def get_file_paths(self, folder):
        """"""
        file_list = glob.glob(os.path.join(folder, "*.csv.gz"))
        file_list.sort()
        return file_list


    def check_availability(self):
        weeks = [self.week1, self.week2, self.week3]
        dates = list(os.walk(self.folder_path))[0][1]
        for week in weeks:
            if week not in dates:
                print("The date you input has no data, "\
                    "here are the available dates:")
                self.see_available_files(silent=False)
                break
        else:
            print("Pattern data available")

#%%
# os.chdir("/Users/yenchenchou/Documents/RMDS_YC/RiskScore/RMDS_COVID19_riskgenerator")
# week_pattern = WeekPattern("data/external/weekly_pattern", "0710", "0722", "0729")
# week_pattern.check_availability()
# week_pattern.get_all_pattern()

