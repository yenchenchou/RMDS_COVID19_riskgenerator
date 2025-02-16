"""
@author: Yen-Chen Chou
"""
import ast

from datetime import datetime

import pandas as pd


class OpenHour:
    """ Clean and Filter POI data from SafeGraph.com

    Arg:
        file_path (str): file path of core_places_data

    Examples:
    >>> from core_store_getter import OpenHour
    >>> open_hours = OpenHour(file_path)
    >>> open_hours.read_data()

    Attributes:
        df (dataframe): final data
        file_path (str): file path of core_places_data
    """
    def __init__(self, file_path):
        self.file_path = file_path
        self.df = None


    def read_data(self):
        """ Get open store data
        Return:
            df (dataframe): open store data
        """
        self.df = pd.read_csv(
            self.file_path,
            usecols=['safegraph_place_id', 'open_hours_dict', "community"])
        self.df = self.df[self.df["community"].notnull()]
        self.df = self.df[["safegraph_place_id", "open_hours_dict"]].copy()
        self.df = self.df[self.df["open_hours_dict"].notnull()].copy()

    @staticmethod
    def __turn_dict_helper(x):
        try:
            return ast.literal_eval(x)
        except ValueError:
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


    def __turn_dict(self):
        self.df["open_hours_dict"] = self.df["open_hours_dict"]\
            .apply(lambda x: self.__turn_dict_helper(x))
        return self.df


    def __tstrp(self, timestring):
        hour, _ = timestring.split(":")
        if int(hour) > 23:
            timestring = "0:00"
        return datetime.strptime(timestring, "%H:%M")


    def __get_hours_periodr(self, val_list):
        """ Galculate operationg hours
        Arg:
            val_list (list): a list of time list,
            may have multiple open time for on POI
        Return:
            max_hours (float): max open hours given day
        """
        max_hours = 0
        if len(val_list) == 0:
            return 0

        for val in val_list:
            open_t, close_t = self.__tstrp(val[0]), self.__tstrp(val[1])
            hours = (close_t - open_t).seconds / 3600
            if hours < 0:
                hours = 24 + hours
            if hours > max_hours:
                max_hours = hours
        return max_hours


    def get_open_hours(self):
        """ Get POI data open store attached
        Return:
            df (dataframe): open store data
        """
        self.df = self.__turn_dict()
        open_hours_ls = list()

        for row in self.df.iterrows():
            place_id, open_hours = row[1][0], row[1][1]
            for key, val_list in open_hours.items():
                hours = self.__get_hours_periodr(val_list)
                row = (place_id, key, hours)
                open_hours_ls.append(row)

        self.df = pd.DataFrame(
            open_hours_ls,
            columns=["safegraph_place_id", "weekday", "open_hours"])

        return self.df
