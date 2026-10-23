from pathlib import Path
from playwright.sync_api import sync_playwright
out=Path('output/validation/role-chooser')
line=Path('output/private/CineConnect_New_Logins_2026-10-17.txt').read_text().splitlines()[1]
parts={k.strip():v.strip() for chunk in line.split('|')[1:] for k,v in [chunk.split(':',1)]}
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True, executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':1440,'height':960},device_scale_factor=1)
    errors=[]
    requests=[]
    page.on('pageerror', lambda e: errors.append('pageerror:'+repr(e)[:600]))
    page.on('response', lambda r: errors.append('HTTP '+str(r.status)+' '+r.url[-100:]) if r.status>=400 else None)
    page.on('requestfailed', lambda r: errors.append('failed:'+r.url[-100:]))
    page.on('request', lambda r: requests.append(r.method+' '+r.url[-90:]) if '/api/' in r.url else None)
    page.goto('https://cineconnect.net/',wait_until='domcontentloaded',timeout=30000)
    page.wait_for_url('**/#/login',timeout=60000)
    page.wait_for_timeout(2000)
    page.mouse.click(830,245)
    page.keyboard.type(parts['username'])
    page.mouse.click(830,302)
    page.keyboard.type(parts['password'])
    page.mouse.click(1000,420)
    page.keyboard.press('Enter')
    page.wait_for_timeout(22000)
    page.screenshot(path=str(out/'live-actor-after-login.png'),full_page=True)
    print('portal_url',page.url,'errors',errors[:8], 'requests',requests[-8:], 'overlay_script',bool(page.locator('script[src="unified_workspaces.js"]').count()))
    page.goto('https://cineconnect.net/#/profile/roles',wait_until='domcontentloaded',timeout=30000)
    page.wait_for_timeout(16000)
    page.screenshot(path=str(out/'live-role-chooser.png'),full_page=True)
    print('chooser_url',page.url,'errors',errors[-8:])
    browser.close()
