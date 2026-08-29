from selenium import webdriver
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup
import openpyxl
import time
import json
import datetime
import os

import config


def _slugify(champ):
    """Champion name -> the URL slug leagueofgraphs.com uses for its page.

    A handful of champions don't match their display name and are patched here; add new
    ones to this chain if a champion's URL changes or a new champion needs a similar fix.
    """
    return (
        champ.replace(' ', '')
        .replace("'", '')
        .replace(".", '')
        .replace("wukong", 'monkeyking')
        .replace("glasc", '')
    )


def _read_chart_history(scripts):
    """Parse the three inline chart datasets embedded in the page's <script> tags."""
    popularityhistory, popularityhistorydate = [], []
    wrhistory, brhistory = [], []

    for script in scripts:
        if script.text.find('graphFuncgraphDD5') != -1:
            data = script.text.split('data: ')
            lines = data[1].split('lines')[0]
            popularityhistoryall = json.loads(lines.split(',\n')[0])
            popularityhistory = [row[1] for row in popularityhistoryall]
            popularityhistorydate = [
                datetime.datetime.fromtimestamp(row[0] / 1000).strftime('%Y-%m-%d')
                for row in popularityhistoryall
            ]
        if script.text.find('graphFuncgraphDD6') != -1:
            data = script.text.split('data: ')
            lines = data[1].split('lines')[0]
            wrhistoryall = json.loads(lines.split(',\n')[0])
            wrhistory = [row[1] for row in wrhistoryall]
        if script.text.find('graphFuncgraphDD7') != -1:
            data = script.text.split('data: ')
            lines = data[1].split('lines')[0]
            brhistoryall = json.loads(lines.split(',\n')[0])
            brhistory = [row[1] for row in brhistoryall]

    return popularityhistory, popularityhistorydate, wrhistory, brhistory


def scrap_champ(url, champ, number_of_champ):
    config.ensure_output_dirs()
    driver = webdriver.Chrome(executable_path=config.CHROMEDRIVER_PATH)
    try:
        print('Scraping champion:', champ)
        url_champ = url + _slugify(champ)
        print('URL:', url_champ)
        driver.get(url_champ)
        time.sleep(config.PAGE_LOAD_DELAY)
        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        scripts = soup.findAll('script')

        workbook = openpyxl.load_workbook(filename=config.SNAPSHOT_WORKBOOK)
        worksheet = workbook.active

        workbookHistory = openpyxl.Workbook()
        workbookHistory.create_sheet(title=config.PATCH_VERSION)
        worksheetHistory = workbookHistory.active

        popularityhistory, popularityhistorydate, wrhistory, brhistory = _read_chart_history(scripts)

        def read_trimmed(xpath):
            # These dropdown summaries render with a trailing character (e.g. a unit
            # symbol) that isn't part of the value, hence trimming the last character.
            text = driver.find_element(By.XPATH, xpath).text
            return text[:len(text) - 1]

        popularity = read_trimmed('//*[@id="graphDD1"]')
        wr = read_trimmed('//*[@id="graphDD2"]')
        banrate = read_trimmed('//*[@id="graphDD3"]')
        main = read_trimmed('//*[@id="graphDD4"]')
        pentakills = driver.find_element(
            By.XPATH, '//*[@id="mainContent"]/div[2]/div[2]/div[5]/div[1]/div/a/div[1]'
        ).text
        gold = driver.find_element(
            By.XPATH, '//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[1]/div/div[1]'
        ).text
        minions = driver.find_element(
            By.XPATH, '//*[@id="mainContent"]/div[2]/div[2]/div[6]/div[2]/div/div[1]'
        ).text
        wards = driver.find_element(
            By.XPATH,
            '/html/body/div[2]/div[3]/div[3]/div[1]/div[2]/div[2]/div[2]/div[6]/div[3]/div/div[1]',
        ).text
        damage = driver.find_element(
            By.XPATH,
            '/html/body/div[2]/div[3]/div[3]/div[1]/div[2]/div[2]/div[2]/div[6]/div[4]/div/div[1]',
        ).text

        # Gold and damage used to be scraped and then silently dropped here; they're now
        # kept, so the saved row matches the schema DataProcessing/data_processing.py and
        # RStudio/ expect: Name, Popularity, WR, Banrate, Main, Pentakills, Gold, Minions,
        # Wards, Damage.
        complete_info = [champ, popularity, wr, banrate, main, pentakills, gold, minions, wards, damage]
        worksheet.append(complete_info)

        for i in range(len(popularityhistorydate)):
            worksheetHistory.cell(row=i + 1, column=1).value = popularityhistorydate[i - 1]
            worksheetHistory.cell(row=i + 1, column=2).value = wrhistory[i - 1]
            worksheetHistory.cell(row=i + 1, column=3).value = popularityhistory[i - 1]
            worksheetHistory.cell(row=i + 1, column=4).value = brhistory[i - 1]

        workbook.save(config.SNAPSHOT_WORKBOOK)
        workbookHistory.save(
            os.path.join(config.CHAMPS_HISTORY_DIR, f'champInfoHistory{champ}.xlsx')
        )
    finally:
        driver.quit()
