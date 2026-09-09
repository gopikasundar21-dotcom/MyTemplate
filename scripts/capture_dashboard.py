"""One-off helper: capture a screenshot of the running MyTemplate dashboard.

Used to generate the homepage hero image so it shows the real MyTemplate UI
(with MyTemplate branding) rather than the old Ignite screenshot.

Usage (app must be running on http://127.0.0.1:5000 with seeded dev users):
    python scripts/capture_dashboard.py
"""
from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:5000"
OUT = "appname/static/public/brand/demo-1.png"


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1280, "height": 800})

        # Log in with the seeded dev user.
        page.goto(f"{BASE}/login")
        page.fill("input[name='email']", "user@example.com")
        page.fill("input[name='password']", "test")
        page.click("button[type='submit']")
        page.wait_for_url("**/dashboard/**", timeout=30000)
        page.wait_for_load_state("networkidle")

        page.screenshot(path=OUT)
        print(f"Saved screenshot to {OUT}")
        browser.close()


if __name__ == "__main__":
    main()
