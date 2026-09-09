"""Backend tests covering two real user-facing concerns:

1. The MyTemplate branding actually renders in the UI (protects the rename).
2. The login -> logout journey ends the session and re-protects the dashboard.

These are intentionally small but exercise flows a real user hits.
"""
import pytest

create_user = True


@pytest.mark.usefixtures("testapp")
class TestBrandingAndLogout:
    def test_landing_page_shows_mytemplate_branding(self, testapp):
        """The public landing page should be branded MyTemplate, not Ignite."""
        response = testapp.get("/", follow_redirects=True)
        body = response.get_data(as_text=True)

        assert response.status_code == 200
        assert "MyTemplate" in body
        # The rename must be complete: no stray Ignite branding in the title/body.
        assert "Ignite" not in body

    def test_login_then_logout_reprotects_dashboard(self, testapp):
        """A logged-in user can reach the dashboard; after logout it redirects to login."""
        # Log in.
        login = testapp.post(
            "/login",
            data={"email": "user@example.com", "password": "safepassword"},
            follow_redirects=True,
        )
        assert login.status_code == 200
        assert "Logged in successfully." in login.get_data(as_text=True)

        # Authenticated: dashboard is reachable.
        dashboard = testapp.get("/dashboard/", follow_redirects=True)
        assert dashboard.status_code == 200
        assert "Dashboard" in dashboard.get_data(as_text=True)

        # Log out.
        logout = testapp.get("/auth/logout", follow_redirects=True)
        assert logout.status_code == 200

        # Unauthenticated: dashboard now redirects to the login page.
        after = testapp.get("/dashboard/", follow_redirects=True)
        assert after.status_code == 200
        body = after.get_data(as_text=True)
        assert "/login" in after.request.path or "Login" in body or "login" in body
