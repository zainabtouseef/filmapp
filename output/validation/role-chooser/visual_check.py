from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('output/validation/role-chooser')
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True, executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':1440,'height':960},device_scale_factor=1)
    errors=[]
    page.on('pageerror', lambda e: errors.append(str(e)[:250]))
    page.goto('https://cineconnect.net/',wait_until='domcontentloaded',timeout=30000)
    page.wait_for_timeout(11000)
    page.screenshot(path=str(out/'live-initial.png'),full_page=True)
    print('url',page.url,'title',page.title(),'errors',len(errors),'body',page.locator('body').inner_text()[:280].replace('\n',' | '))
    browser.close()
