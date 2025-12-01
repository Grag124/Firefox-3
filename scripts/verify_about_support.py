#!/usr/bin/env python3
"""Simple headless verification for Firefox about:support using Selenium.

Requires:
  - Python packages: selenium
  - geckodriver available in scripts/bin/geckodriver (or in PATH)
  - Firefox binary at Firefox2/firefox/firefox

This script connects to geckodriver, opens about:support, and prints
the Application Version and whether WebRender is enabled according to the page.
"""
import os
import sys
import time

from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service


def find_text_in_source(src, keyword):
    return keyword in src


def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    firefox_bin = os.path.join(root, 'Firefox2', 'firefox', 'firefox')
    gecko = os.path.join(root, 'scripts', 'bin', 'geckodriver')

    if not os.path.exists(firefox_bin):
        print('Firefox binary not found at', firefox_bin)
        sys.exit(2)
    if not os.path.exists(gecko):
        print('geckodriver not found at', gecko)
        sys.exit(3)

    options = Options()
    options.headless = True
    options.binary_location = firefox_bin

    service = Service(executable_path=gecko)
    print('Starting geckodriver and Firefox (headless) ...')
    driver = webdriver.Firefox(service=service, options=options)

    try:
        driver.set_page_load_timeout(30)
        driver.get('about:support')
        time.sleep(0.5)
        src = driver.page_source

        # Try to find Application Version
        # The page contains 'Application Basics' table; search for 'Application Version'
        version = 'unknown'
        for line in src.splitlines():
            if 'Application Version' in line:
                # poor-man parsing: extract nearby text
                idx = line.find('Application Version')
                snippet = line[idx:]
                version = snippet
                break

        webrender = any('webrender' in line.lower() for line in src.splitlines())

        print('Application Version snippet:', version)
        print('WebRender presence in about:support page:', webrender)

        if not webrender:
            print('\nERROR: WebRender not detected on about:support. Failing verification!')
            sys.exit(3)
        else:
            print('\nOK: WebRender detected on about:support')
    finally:
        driver.quit()


if __name__ == '__main__':
    main()
