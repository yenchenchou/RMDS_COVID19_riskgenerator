"""
@author: Yen-Chen Chou
"""
import glob
import json
import os
import pandas as pd

class POI:
    """ Clean and Filter POI data from SafeGraph.com(Core Places)
    Arg:
        folder_path (str): file path of core_places_data

    Examples:
    >>> from core_poi_getter import POI
    >>> poi_getter = POI(folder_path)
    >>> poi_getter.read_mapper()
    >>> df_poi = poi_getter.get_poi()

    Attributes:
        folder_path (str): file path of core_places_data
        df (dataframe): final data
        mapper_dict (str): zipcode and community/city key value pairs
    """
    def __init__(self, folder_path):
        self.folder_path = folder_path
        self.df = pd.DataFrame()
        self.mapper_dict = None


    def get_poi(self):
        """ Get poi data with community names in CA
        Return:
            df (dataframe): poi data
        """
        folder_path_exp = os.path.join(self.folder_path, "*.csv.gz")
        file_paths = glob.glob(folder_path_exp)
        for paths in file_paths:
            df_tmp = pd.read_csv(paths, compression="gzip")
            df_tmp = df_tmp[df_tmp["region"] == "CA"].copy()
            df_tmp = df_tmp[["safegraph_place_id",
                             "latitude",
                             "longitude",
                             "open_hours",
                             "city",
                             "postal_code"]].copy()
            df_tmp.rename(columns={"open_hours": "open_hours_dict"}, inplace=True)
            df_tmp["community"] = df_tmp["postal_code"].apply(lambda x: self.mapping(x))
            df_tmp = df_tmp[df_tmp["community"].notnull()]
            df_tmp.drop(["postal_code"], axis=1, inplace=True)
            self.df = pd.concat([self.df, df_tmp], axis=0, ignore_index=True)
        return self.df


    def read_mapper(self):
        """ Read dictionary with zipcode as key and community as value
        Return:
            mapper_dict (dict): zipcode and community/city key value pairs
        """
        with open("data/internal/RMDS_zipcode_mapper.json") as file:
            self.mapper_dict = json.load(file)
        self.mapper_dict = {str(key):val for key, val in self.mapper_dict.items()}


    def mapping(self, x):
        """ Error handler for read_mapper function
        Arg:
            x (str): zipcode
        Return:
            community (str): community/city name
        """
        try:
            community = self.mapper_dict[str(x)]
            return community
        except KeyError:
            pass
