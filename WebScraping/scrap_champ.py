    
from selenium import webdriver
from bs4 import BeautifulSoup
from xml.etree import ElementTree
import csv
import time
import os
import json


def scrap_champ(url):
    driver = webdriver.Chrome(executable_path = 'C:/WebDriver/bin/chromedriver.exe')
    driver.get(url)
    time.sleep(10)


    # wrhistory = driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[1]/div[1]/script')

    popularity =  driver.find_element_by_xpath('//*[@id="graphDD1"]')
    print(popularity.text)
    wr =  driver.find_element_by_xpath('//*[@id="graphDD2"]')
    print(wr.text)
    banrate =  driver.find_element_by_xpath('//*[@id="graphDD3"]')
    print(banrate.text)
    main =  driver.find_element_by_xpath('//*[@id="graphDD4"]')
    print(main.text)

    pentakills =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[5]/div[1]/div/a/div[1]')
    print(pentakills.text)
    gold =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[1]/div/div[1]')
    print(gold.text)
    minions =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[2]/div/div[1]')
    print(minions.text)
    
    main =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[3]/div/div[1]')
    print(main.text)
    main =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[4]/div/div[1]')
    print(main.text)
    main =  driver.find_element_by_xpath('//*[@id="graphDD4"]')
    print(main.text)
    