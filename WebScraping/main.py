# Import libraries
from selenium import webdriver
from bs4 import BeautifulSoup
import csv
import time
import os

# Global variables
SCROLL_PAUSE_TIME = 0.5

# Configuration of webdriver to use Google Chrome browser
driver = webdriver.Chrome(executable_path = 'C:/WebDriver/bin/chromedriver.exe')
url='https://www.leagueofgraphs.com/es/champions/stats'
driver.get(url)
time.sleep(5)
"""
# Scrapping pages
k = 1
for k in range(1, 2):
    url='https://www.fotocasa.es/es/comprar/viviendas/madrid-capital/todas-las-zonas/l/'+str(k)+'?combinedLocationIds=724%2C14%2C28%2C173%2C0%2C28079%2C0%2C0%2C0&latitude=40.4096&longitude=-3.6862'
    
    print('')
    print('')
    print('*****  PAGINA ', k, ' *****')
    print('')

    # Go to specific URL
    driver.get(url)
    # driver.fullscreen_window()
    time.sleep(5)

    try:
        # Accept cookies
        driver.find_element_by_xpath('/html/body/div[3]/div/div/footer/div/button[2]').click()
        time.sleep(3)
    except:
        pass
    # Get the screen height of the web
    screen_height = driver.execute_script("return window.screen.height;")   
    i = 1

    # Scroll action
    while True:
        # Scroll one screen height each time
        driver.execute_script("window.scrollTo(0, {screen_height}*{i});".format(screen_height=screen_height, i=i))  
        i += 1
        time.sleep(SCROLL_PAUSE_TIME)
        
        # Update scroll height each time after scrolled, as the scroll height can change after we scrolled the page
        scroll_height = driver.execute_script("return document.body.scrollHeight;")  
        
        # Break the loop when the height we need to scroll to is larger than the total scroll height
        if (screen_height) * i > scroll_height:
            break
    buildings = driver.find_elements_by_class_name('re-Card-link')

    i = 0
    for building in buildings:
        i += 1
        try:
            # Call scrap_page function
            districtLabel = driver.find_element_by_xpath('/html/body/div[1]/div[3]/div/div[4]/div[2]/div[1]/main/div[3]/section/article['+str(i)+']/div/div[2]/a/div[3]/h3')
            districtWaste = ''
            try:
                districtWaste = districtLabel.find_element_by_tag_name('span').text
            except:
                pass
            districtNoWaste = districtLabel.text[len(districtWaste):len(districtLabel.text)]
            districtSplitted = districtNoWaste.split(' ')
            district = districtSplitted[len(districtSplitted)-1]
            if (district == 'Vallecas'):
                district = districtSplitted[len(districtSplitted)-3]+' '+districtSplitted[len(districtSplitted)-2]+' '+districtSplitted[len(districtSplitted)-1]
            if (district == 'Lineal' or district == 'Blas'):
                district = districtSplitted[len(districtSplitted)-2]+' '+districtSplitted[len(districtSplitted)-1]
        
            scrap_page(building.get_attribute('href'), district)
        except:
            pass
        
"""