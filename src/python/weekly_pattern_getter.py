"""
@author: Yen-Chen Chou
"""
import glob
import os
from pathlib import Path

import pandas as pd

from _file_display import DisplayablePath

class WeekPattern:
    """ Clean and Filter weekly pattern data from SafeGraph.com(Core Places)
    Args:
        folder_path (str): weekly pattern data parent folder
        week1 (str): week1 pattern data folder
        week2 (str): week2 pattern data folder
        week3 (str): week3 pattern data folder

    Examples:
    >>> FOLDER_PATH = "data/external/weekly_pattern"
    >>> WEEK1, WEEK2, WEEK3 = "0715", "0722", "0729"
    >>> week_pattern = WeekPattern(FOLDER_PATH, WEEK1, WEEK2, WEEK3)
    >>> week_pattern.check_availability()
    >>> week_pattern.get_all_pattern()

    Attributes:
        folder_path (str): weekly pattern data parent folder
        week1 (str): week1 pattern data folder
        week2 (str): week2 pattern data folder
        week3 (str): week3 pattern data folder
        df_pattern (dataframe): final data
        df_poi (dataframe): processed POI data
        folder_names (list): weekly pattern folder name accoring user input
        paths (list): .csv.gz file paths for one single folder
    """
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
        """ See available weekly pattern files
        Args:
            silent (bool, optional): print file tree. Defaults to True.
        """
        self.paths = DisplayablePath.make_tree(Path(self.folder_path))
        if silent:
            pass
        else:
            for path in self.paths:
                print(path.displayable())


    def get_all_pattern(self):
        """Get all three pattern data"""
        self.get_folders()
        if len(self.folder_names) == 0:
            print("All processed pattern exist")
        else:
            for folder in self.folder_names:
                file_list = self.get_file_paths(folder)
                self.df_pattern = self.get_one_pattern(file_list)
                file_save_path = "data/processed/pattern-" + folder[-4:]
                self.df_pattern.to_csv(file_save_path+".csv", index=False)
                self.df_pattern = None
                print(file_save_path, "saved!")


    def get_one_pattern(self, file_list):
        """ Get one week filtered pattern data
        Args:
            file_list (str): a list of files in one day folder
        Returns:
            df_pattern: filtered pattern data
        """
        for path in file_list:
            df_filter = self.get_filter(path)
            self.df_pattern = pd.concat(
                [self.df_pattern, df_filter],
                axis=0,
                ignore_index=True)
        return self.df_pattern


    def get_filter(self, path):
        """Filter dataframe
        Args:
            path (str): path to file
        Returns:
            df_tmp (dataframe): filtered dataframe
        """
        df_tmp = pd.read_csv(
            path,
            usecols=["safegraph_place_id",
                     "visits_by_day",
                     "visits_by_each_hour",
                     "median_dwell",
                     "date_range_start",
                     "date_range_end"],
            compression="gzip")
        df_tmp = pd.merge(df_tmp, self.df_poi, how="inner")
        return df_tmp


    def get_folders(self):
        """Get all folders for pattern data"""
        file_names = list(os.walk("data/processed"))[0][2]
        weeks = [self.week1, self.week2, self.week3]

        for name in file_names:
            if self.week1 in name:
                weeks.remove(self.week1)
                print(f"weekly pattern {self.week1} alreadly exist, skip process")
            if self.week2 in name:
                weeks.remove(self.week2)
                print(f"weekly pattern {self.week2} alreadly exist, skip process")
            if self.week3 in name:
                weeks.remove(self.week3)
                print(f"weekly pattern {self.week3} alreadly exist, skip process")
        
        if len(weeks) == 0:
            self.folder_names = []
        else:
            for week in weeks:
                self.folder_names.append(os.path.join(self.folder_path, week))


    @staticmethod
    def get_file_paths(folder):
        """ Get .csv.gz file paths for one single folder
        Args:
            folder (str): folder to the files on one day
        Returns:
            file_list (list): file list
        """
        file_list = glob.glob(os.path.join(folder, "*.csv.gz"))
        file_list.sort()
        return file_list


    def check_availability(self):
        """ Check existence of data that user specify"""
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
