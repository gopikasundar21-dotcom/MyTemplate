"""Playwright UI test for the core login flow.

This drives a real Chromium browser through the journey a customer takes on
day one: open the login page, type credentials, submit, and land on the
dashboard. It also confirms the MyTemplate rename is visible in the browser.
"""
import pytest
from conftest import UI_USER_EMAIL, UI_USER_PASSWORD

pytestmark = pytest.mark.ui


def test_user_can_log_in_through_the_browser(page, live_server):
    # A real user opens the login page.
    page.goto(f"{live_server}/login")

    # The page is branded MyTemplate (guards the Ignite -> MyTemplate rename).
    assert "MyTemplate" in page.title()

    # Fill in the login form and submit it.
    page.fill("input[name='email']", UI_USER_EMAIL)
    page.fill("input[name='password']", UI_USER_PASSWORD)
    page.click("button[type='submit']")

    # After a successful login the app redirects to the dashboard and flashes
    # a success message. Allow extra time for cold browser/server start in CI.
    page.wait_for_url("**/dashboard/**", timeout=30000)
    body = page.content()
    assert "Logged in successfully." in body
    assert "Dashboard" in body


def test_invalid_login_keeps_user_on_login_page(page, live_server):
    # Wrong password should not let the user in.
    page.goto(f"{live_server}/login")
    page.fill("input[name='email']", UI_USER_EMAIL)
    page.fill("input[name='password']", "definitely-wrong")
    page.click("button[type='submit']")

    # The user stays on the login page and sees an error.
    page.wait_for_load_state("networkidle")
    assert "/dashboard/" not in page.url
    assert "Invalid email or password" in page.content()
