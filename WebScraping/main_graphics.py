# Scrapes combined history graphs (popularity / win rate / ban rate) across ALL champions,
# needed as input for the time-series analysis in RStudio/.
# See config.py for every path/setting this script uses, all overridable via env vars.
from selenium import webdriver
from selenium.webdriver.common.by import By
from openpyxl import Workbook
import time

import config
from scrap_graphics import scrap_graphics

config.ensure_output_dirs()

# Configuration of webdriver to use Google Chrome browser
driver = webdriver.Chrome(executable_path=config.CHROMEDRIVER_PATH)
driver.get(config.URL)
time.sleep(3)
driver.find_element(By.XPATH, '//*[@id="championsFilter"]/a').click()

champ_bucket = []

Workbook().save(filename=config.POP_HISTORY_WORKBOOK)
Workbook().save(filename=config.WR_HISTORY_WORKBOOK)
Workbook().save(filename=config.BR_HISTORY_WORKBOOK)

for i in range(2, config.NUMBER_OF_CHAMPS):
    try:
        champ_bucket.append(
            driver.find_element(By.XPATH, f'//*[@id="drop-champions"]/ul/li[{i}]').text.lower()
        )
    except Exception:
        pass

print(champ_bucket)
print(len(champ_bucket))

# Only needed to read the champion list; each champion is scraped in its own driver
# session (see scrap_graphics.py), so this one can close before that loop starts.
driver.quit()

number_of_champ = 1
failed_champs = []
for champ_string in champ_bucket:
    try:
        scrap_graphics(config.URL_ESP, champ_string, number_of_champ)
    except Exception as exc:
        print(f"[main_graphics] Skipping {champ_string!r} after an error: {exc}")
        failed_champs.append(champ_string)
    number_of_champ += 1

if failed_champs:
    print(f"[main_graphics] Finished with {len(failed_champs)} champion(s) skipped: {failed_champs}")
