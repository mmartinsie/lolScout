import requests
from selenium import webdriver
from bs4 import BeautifulSoup
from xml.etree import ElementTree
import csv
import time
import os
import json


def scrap_champ(url,champ):
    driver = webdriver.Chrome(executable_path = 'C:/WebDriver/bin/chromedriver.exe')
    url_esp = url+champ.replace(' ','').replace("'",'').replace(".",'').replace("wukong",'monkeyking')
    print('url',url_esp)
    driver.get(url_esp)
    time.sleep(5)
    html = driver.page_source
    soup = BeautifulSoup(html, 'html.parser')
    scripts = soup.findAll('script')
    with open('champs_information.csv', 'a', newline='') as csv_file:
        headers = ['Name', 'Popularity', 'WR','Banrate', 'Main', 'Pentakills', 'Gold', 'Minions', 'Wards', 'Damage', 'Phistory', 'WRhistory', 'BRhistory'] 
        writer = csv.DictWriter(csv_file, fieldnames=headers)

        wrhistoryscript = ''
        for script in scripts:
            if script.text.find('graphFuncgraphDD5')!=-1:
                popularityhistoryscript = script.text
                data = popularityhistoryscript.split('data: ')
                lines = data[1].split('lines')[0]
                popularityhistory = lines.split(',\n')[0]
            if script.text.find('graphFuncgraphDD6')!=-1:
                wrhistoryscript = script.text
                data = wrhistoryscript.split('data')
                lines = data[1].split('lines')[0]
                wrhistory = lines.split(',\n')[0]
            if script.text.find('graphFuncgraphDD7')!=-1:
                brhistoryscript = script.text
                data = wrhistoryscript.split('data')
                lines = data[1].split('lines')[0]
                brhistory = lines.split(',\n')[0]
    	
        popularity =  driver.find_element_by_xpath('//*[@id="graphDD1"]').text
        a = slice(len(popularity)-1)
        popularity = popularity[a]
        print(popularity)

        wr =  driver.find_element_by_xpath('//*[@id="graphDD2"]').text
        a = slice(len(wr)-1)
        wr = wr[a]
        print(wr)

        banrate =  driver.find_element_by_xpath('//*[@id="graphDD3"]').text
        a = slice(len(banrate)-1)
        banrate = banrate[a]
        print(banrate)

        main =  driver.find_element_by_xpath('//*[@id="graphDD4"]').text
        a = slice(len(main)-1)
        main = main[a]
        print(main)

        pentakills =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[5]/div[1]/div/a/div[1]').text
        print(pentakills)
        gold =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[1]/div/div[1]').text
        print(gold)
        minions =  driver.find_element_by_xpath('//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[2]/div/div[1]').text
        print(minions)

        wards =  driver.find_element_by_xpath('/html/body/div[2]/div[3]/div[3]/div[1]/div[2]/div[2]/div[2]/div[6]/div[3]/div/div[1]').text
        print(wards)
        damage =  driver.find_element_by_xpath('/html/body/div[2]/div[3]/div[3]/div[1]/div[2]/div[2]/div[2]/div[6]/div[4]/div/div[1]').text
        print(damage)
    
        writer.writerow({'Name': champ,'Popularity': popularity, 'WR': wr, 'Banrate': banrate, 'Main': main, 'Pentakills': pentakills, 'Gold': gold, 'Minions': minions, 'Wards': wards, 'Damage': damage, 'Phistory': popularityhistory, 'WRhistory': wrhistory, 'BRhistory': brhistory})
        driver.close()