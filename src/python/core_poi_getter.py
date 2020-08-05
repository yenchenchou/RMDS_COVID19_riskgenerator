"""
@author: Yen-Chen Chou
"""
import json
import pandas as pd

class POI:
    """ Clean and Filter POI data from SafeGraph.com(Core Places)
    Arg:
        file_path (str): file path of core_places_data

    Examples:
    >>> from core_poi_getter import POI
    >>> poi_getter = POI(file_path)
    >>> poi_getter.read_mapper()
    >>> df_poi = poi_getter.get_poi()

    Attributes:
        file_path (str): file path of core_places_data
        df (dataframe): final data
        mapper_dict (str): zipcode and community/city key value pairs
    """
    def __init__(self, file_path):
        self.file_path = file_path
        self.df = None
        self.mapper_dict = None


    def get_poi(self):
        """ Get poi data with community names in CA
        Return:
            df (dataframe): poi data
        """
        # filter_ls = ["Restaurants and Other Eating Places", "Grocery Stores"]
        #     df = df[df["top_category"].isin(filter_ls)].copy()
        self.df = pd.read_csv(self.file_path, compression="gzip")
        self.df = self.df[self.df["region"] == "CA"].copy()
        self.df = self.df[["safegraph_place_id",
                           "latitude",
                           "longitude",
                           "city",
                           "postal_code"]]
        self.df["community"] = self.df["postal_code"].apply(lambda x: self.mapping(x))
        self.df = self.df[self.df["community"].notnull()]
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
