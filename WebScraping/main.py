# Scrapes a single patch snapshot: one row per champion + one history workbook per champion.
# See config.py for every path/setting this script uses, all overridable via env vars.
from selenium import webdriver
from selenium.webdriver.common.by import By
from openpyxl import Workbook
import time

import config
from scrap_champ import scrap_champ

config.ensure_output_dirs()

# Configuration of webdriver to use Google Chrome browser
driver = webdriver.Chrome(executable_path=config.CHROMEDRIVER_PATH)
driver.get(config.URL)
time.sleep(3)
driver.find_element(By.XPATH, '//*[@id="championsFilter"]/a').click()

champ_bucket = []

wb = Workbook()
wb.create_sheet(title=config.PATCH_VERSION)
wb.save(filename=config.SNAPSHOT_WORKBOOK)

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
# session (see scrap_champ.py), so this one can close before that loop starts.
driver.quit()

number_of_champ = 0
failed_champs = []
for champ_string in champ_bucket:
    try:
        scrap_champ(config.URL_ESP, champ_string, number_of_champ)
    except Exception as exc:
        print(f"[main] Skipping {champ_string!r} after an error: {exc}")
        failed_champs.append(champ_string)
    number_of_champ += 1

if failed_champs:
    print(f"[main] Finished with {len(failed_champs)} champion(s) skipped: {failed_champs}")
