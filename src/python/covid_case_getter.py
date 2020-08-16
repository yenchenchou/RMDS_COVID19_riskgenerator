"""
@author: Yen-Chen Chou
"""
import csv

import bs4
import pandas as pd
import requests


class WebCsvDownload:
    """ Crawl data from publichealth.lacounty.gov

    Arg:
        url (str): link address of the csv url

    Examples:
    >>> from covid_case_getter import WebCsvDownload
    >>> CASE_URL = "<the link address>"
    >>> case_crawler = WebCsvDownload(CASE_URL)
    >>> case_crawler.save_csv()

    Attributes:
        url (str): link address of the csv url
        obj (obj): requested object
        result_list (list): COVID-19 data in list format
    """

    def __init__(self, url):
        self.url = url
        self.obj = None
        self.result_list = None


    def __get_url_connect(self):
        try:
            self.obj = requests.get(self.url)
        except:
            if self.obj.status_code >= 400 and self.obj.status_codeatus_code <= 499:
                raise Exception("Client Error")
            elif self.obj.status_code >= 500 and self.obj.status_codeatus_code <= 599:
                raise Exception("Server Error, url changed")
            else:
                raise Exception("Not Client or Server Error, please update the code")


    def fetch_csv(self):
        """Get COVID-19 through the web and save as list"""
        with requests.Session() as session:
            self.__get_url_connect()
            decoded_content = self.obj.content.decode('utf-8')
            csv_obj = csv.reader(decoded_content.splitlines(), delimiter=',')
            self.result_list = list(csv_obj)


    def save_csv(self):
        """Write COVI-19 case list as csv file"""

        self.fetch_csv()

        if "deaths_final" in self.result_list[0]:
            with open("data/external/LA_County_Covid19_CSA_case_death_table.csv", "w") as csv_file:
                csv_obj = csv.writer(csv_file, delimiter=",", dialect="excel")
                csv_obj.writerows(self.result_list)
                print("Saved LA_County_Covid19_CSA_case_death_table.csv")
    
        elif "persons_tested_final" in self.result_list[0]:
            with open("data/external/LA_County_Covid19_CSA_testing_table.csv", "w") as csv_file:
                csv_obj = csv.writer(csv_file, delimiter=",", dialect="excel")
                csv_obj.writerows(self.result_list)
                print("Saved LA_County_Covid19_CSA_testing_table.csv")

        else:
            print("File not found")

