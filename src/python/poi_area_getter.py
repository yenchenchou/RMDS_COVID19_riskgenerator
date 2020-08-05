"""
@author: Yen-Chen Chou
"""
import pandas as pd

class POIArea(object):
    """ Clean and Filter POI data from third party 
    contributors in SafeGraph.com

    Examples:
    >>> from poi_area_getter import POIArea
    >>> area_getter = POIArea()
    >>> df_area = area_getter.get_area()
    """
    def __init__(self):
        self.df_area = None


    def get_area(self):
        """ Get poi area data

        Return:
            df (dataframe): area data

        """
        self.df_area = pd.read_csv(
            "data/external/SafeGraphPlacesGeoSupplementSquareFeet.csv.gz",
            compression="gzip")
        # self.df_area = self.df_area[self.df_area["iso_country_code"] == "CA"]
        self.df_area = self.df_area[["safegraph_place_id", "area_square_feet"]]

        return self.df_area
