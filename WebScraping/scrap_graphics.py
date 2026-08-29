from selenium import webdriver
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup
import openpyxl
import time
import json
import datetime

import config
from scrap_champ import _slugify, _read_chart_history


def scrap_graphics(url, champ, number_of_champ):
    config.ensure_output_dirs()
    driver = webdriver.Chrome(executable_path=config.CHROMEDRIVER_PATH)
    try:
        print('Scraping champion history:', champ)
        url_champ = url + _slugify(champ)
        print('URL:', url_champ)
        driver.get(url_champ)
        time.sleep(config.PAGE_LOAD_DELAY)
        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        scripts = soup.findAll('script')

        workbookPopHistory = openpyxl.load_workbook(filename=config.POP_HISTORY_WORKBOOK)
        worksheetPopHistory = workbookPopHistory.active

        workbookWRHistory = openpyxl.load_workbook(filename=config.WR_HISTORY_WORKBOOK)
        worksheetWRHistory = workbookWRHistory.active

        workbookBRHistory = openpyxl.load_workbook(filename=config.BR_HISTORY_WORKBOOK)
        worksheetBRHistory = workbookBRHistory.active

        popularityhistory, popularityhistorydate, wrhistory, brhistory = _read_chart_history(scripts)
        # Combined workbooks are built oldest-first (one column per champion), while the
        # per-champion workbooks in scrap_champ.py keep the site's newest-first order.
        popularityhistory = popularityhistory[::-1]
        popularityhistorydate = popularityhistorydate[::-1]
        wrhistory = wrhistory[::-1]
        brhistory = brhistory[::-1]

        for i in range(len(popularityhistorydate)):
            worksheetPopHistory.cell(row=i + 1, column=1).value = popularityhistorydate[i - 1]
            worksheetPopHistory.cell(row=i + 1, column=1 + number_of_champ).value = popularityhistory[i - 1]

            worksheetWRHistory.cell(row=i + 1, column=1).value = popularityhistorydate[i - 1]
            worksheetWRHistory.cell(row=i + 1, column=1 + number_of_champ).value = wrhistory[i - 1]

            worksheetBRHistory.cell(row=i + 1, column=1).value = popularityhistorydate[i - 1]
            worksheetBRHistory.cell(row=i + 1, column=1 + number_of_champ).value = brhistory[i - 1]

        worksheetPopHistory.cell(row=1, column=1).value = "date"
        worksheetWRHistory.cell(row=1, column=1).value = "date"
        worksheetBRHistory.cell(row=1, column=1).value = "date"

        worksheetPopHistory.cell(row=1, column=1 + number_of_champ).value = champ
        worksheetWRHistory.cell(row=1, column=1 + number_of_champ).value = champ
        worksheetBRHistory.cell(row=1, column=1 + number_of_champ).value = champ

        workbookPopHistory.save(config.POP_HISTORY_WORKBOOK)
        workbookWRHistory.save(config.WR_HISTORY_WORKBOOK)
        workbookBRHistory.save(config.BR_HISTORY_WORKBOOK)
    finally:
        driver.quit()
