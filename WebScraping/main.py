# Import libraries
from selenium import webdriver
from bs4 import BeautifulSoup
from xml.etree import ElementTree
from scrap_champ import scrap_champ
import csv
import time
import os
import json

# Global variables
NUMBER_OF_CHAMPS = 156
URL='https://www.leagueofgraphs.com/es/champions/stats/'

# Configuration of webdriver to use Google Chrome browser
driver = webdriver.Chrome(executable_path = 'C:/WebDriver/bin/chromedriver.exe')
driver.get(URL)
time.sleep(3)
# driver.maximize_window()
driver.find_element_by_xpath('//*[@id="championsFilter"]/a').click()

allChampionList = driver.find_element_by_xpath('//*[@id="drop-champions"]/ul')
champ_bucket = []


i = 2
for i in range(2, 4):
   
    try:
        # driver.find_element_by_xpath('//*[@id="drop-champions"]/ul/li['+str(i)+']').click()
        champ_bucket.append(driver.find_element_by_xpath('//*[@id="drop-champions"]/ul/li['+str(i)+']').text.lower())
        
    except:
        pass
print(champ_bucket)
print(len(champ_bucket))

for champ_string in champ_bucket:
    scrap_champ(URL+champ_string)

    # continue_link = driver.find_element_by_partial_link_text('graphFuncgraphDD5')
    # print(continue_link)
    
# print(allChampionList.text)

# champUrlList = allChampionList.find_all("li")
# print(champUrlList)