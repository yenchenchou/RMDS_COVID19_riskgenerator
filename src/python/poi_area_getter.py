"""
@author: Yen-Chen Chou
"""
import pandas as pd

class POIArea(object):

    def __init__(self):
        self.df_area = None


    def get_area(self):

        self.df_area = pd.read_csv(
            "data/external/SafeGraphPlacesGeoSupplementSquareFeet.csv.gz",
            compression="gzip")
        self.df_area = self.df_area[self.df_area["iso_country_code"] == "CA"]
        self.df_area = self.df_area[["safegraph_place_id", "area_square_feet"]]

        return self.df_area
