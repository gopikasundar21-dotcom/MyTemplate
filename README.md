# MyTemplate for Flask

MyTemplate is a scaffold for starting new SaaS applications built using Python and Flask. It takes care of the boilerplate code (like User Registration, OAuth, Teams, and Billing), allowing you to focus on building your application. MyTemplate is built upon best practices for modern Flask applications.

> MyTemplate is based on the open-source [Ignite for Flask](https://github.com/Sumukh/Ignite) starter.

## Features

| Features                              | Status                                       | Details                                                                                    |
| ------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------ |
| User Authentication                   | ✅                                           | User Login, Registration, Forgot Password, Email Confirmation                              |
| OAuth Login                           | ✅                                           | Login or Register with Google, Twitter, Facebook, etc.                                     |
| Teams/Groups                          | ✅                                           | Multi user teams & groups (with Invite Emails)                                             |
| User Export & Deletion Request        | ✅                                           | Allows users to export their data (for GDPR compliance)                                    |
| API                                   | ✅                                           | API (with user tokens) users to access data                                                |
| Stripe Product Checkout               | ✅                                           | One time item purchases with credit cards and receipts (using Stripe)                      |
| Heroku/Docker Deployment              | ✅                                           | Deployment instructions for some platforms. Works on AWS & Google Cloud                    |
| Send Emails                           | ✅                                           | Send email notifications from the application                                              |
| Admin Dashboard                       | ✅                                           | Admin dashboard to edit data                                                               |
| File Uploads                          | ✅                                           | File uploads to cloud storage providers                                                    |
| Basic Test Suite                      | ✅                                           | Starting point for you to build out tests                                                  |
| VS Code Debugger & Editor             | ✅                                           | Configured to make you productive                                                          |
| Tested on Windows 10, OSX, and Ubuntu | ✅                                           | Using Python 3                                                                             |
| SaaS Recurring Billing                | 💲                                           | Team Billing, Usage Based Billing or Unlimited Plans                                       |
| Commercial Usage                      | 💲 (License Required)                        | Commercial Usage requires a purchased license                                              |
| Video Content                         | 💲                                           | Available as part of [the Fullstack Flask course](https://www.newline.co/fullstack-flask/) |

## Setup

Python 3.12+ is required. Install it [from Python.org](https://www.python.org/downloads/).

### macOS / Linux

```bash
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt            # runtime dependencies
pip install -r requirements-dev.txt        # test/lint/security tooling (optional for just running the app)

APPNAME_ENV=dev ./manage.py resetdb        # create + seed the local sqlite DB
FLASK_APP=manage flask --debug run         # serve on http://localhost:5000
```

### Windows (PowerShell)

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1

pip install -r requirements.txt
pip install -r requirements-dev.txt

$env:APPNAME_ENV = "dev"; python .\manage.py resetdb
$env:FLASK_APP = "manage"; flask --debug run
```

Then open http://localhost:5000 and log in with the seeded dev account:

- `user@example.com` / `test`
- `admin@example.com` / `admin`

## AI Agent Guide

If you are using an AI coding agent, start with:

- `AGENTS.md` for repo-specific workflow and architecture guidance
- `documentation/AGENT_QUICKSTART.md` for copy-paste setup/test commands
- `make agent-setup`, `make agent-smoke`, and `make agent-test` for standard agent checks

## Development

```
# Development
# If using a virtual env: source env/bin/activate
./manage.py resetdb # to seed data
FLASK_APP=manage flask --debug run

# Go to localhost:5000 in a browser and click on Login
# Login with the following credentials "user@example.com", "test

# Production documentation in the repository.
```

## Quality Pipeline

MyTemplate ships with a repeatable quality pipeline that runs the same checks
locally and in CI:

| Check              | Tool               | Report artifact                       |
| ------------------ | ------------------ | ------------------------------------- |
| Backend unit tests | pytest             | `reports/junit-backend.xml`           |
| UI tests           | Playwright         | `reports/junit-ui.xml`                |
| Coverage           | pytest-cov         | `reports/coverage.xml`, `reports/coverage_html/index.html` |
| Static analysis    | Ruff               | `reports/ruff.json`                   |
| Security scan      | Bandit             | `reports/bandit.json`                 |

All reports are written to the `reports/` directory so they are easy to find
and review after a run.

### One-time setup

The pipeline needs the dev tooling and a browser for Playwright:

```bash
pip install -r requirements-dev.txt
python -m playwright install chromium
```

### Run everything

**macOS / Linux (Make):**

```bash
make ci          # lint + security + backend tests + UI tests + report summary
```

Individual stages are also available: `make lint`, `make security`, `make test`,
`make ui-test`, `make report`, `make clean`.

**Windows (PowerShell):**

`make` is often unavailable on Windows, so an equivalent script mirrors every
Make target:

```powershell
pwsh ./run_checks.ps1                 # full pipeline (same as `make ci`)
pwsh ./run_checks.ps1 -Task lint      # a single stage: lint|security|test|ui-test|report
```

Both runners exit non-zero if any gating check fails, so CI can rely on them.

> Note: `tests/test_config.py::TestConfig::test_prod_config` is deselected in the
> pipeline because it requires a live Redis server. Re-enable it once Redis is
> wired into your environment.

### Continuous Integration

`.github/workflows/ci.yml` runs the whole pipeline on every push and pull
request, then uploads the `reports/` directory as a downloadable **`quality-reports`**
artifact and publishes a test-results summary to the run.

### Local Secrets

To configure OAuth login and Stripe billing in development, you will need to set some environment variables. See `.env.local.sample` for an example.

```bash
cp .env.local.sample .env.local
# Edit .env.local with your Stripe & Google test keys
source .env.local
FLASK_APP=manage flask --debug run
```

You may also want to change some of the constants in `appname.constants` and the `services/branding.py` file to change the name of the application in the UI.

## Deployment

MyTemplate is not tied to a specific platform for deployment, but it works well on [Heroku](http://heroku.com) and [Dokku](http://dokku.viewdocs.io/dokku/) with minimal configuration.

It is also designed to work well on other cloud providers such as AWS, Google Cloud, and DigitalOcean.

Documentation is currently provided for installations on Dokku.

## Stripe Webhooks Locally

- Install the [Stripe CLI](https://stripe.com/docs/stripe-cli)
- Login to the Stripe CLI (`stripe login`)
- Run `stripe listen --forward-to localhost:5000/webhooks/stripe`
- Use the webhook secret and configure your app to use it (`export STRIPE_WEBHOOK_SECRET=whsec_...`)
- To replay an event in a seperate console: `stripe events resend evt_XYZ`

## Screenshots

| Screenshot                              | Name                                                    |
| --------------------------------------- | ------------------------------------------------------- |
| Login / Signup / OAuth / Password Reset | ![login](documentation/screenshots/login.png)           |
| Dashboard                               | ![Dashboard](documentation/screenshots/dashboard.png)   |
| Saas Subscription Billing + Console     | ![Billing](documentation/screenshots/billing.png)       |
| Teams                                   | ![Team](documentation/screenshots/team.png)             |
| GDPR/Legal                              | ![GDPR](documentation/screenshots/gdpr.png)             |
| Admin                                   | ![Admin](documentation/screenshots/admin.png)           |
| API Tokens                              | ![API](documentation/screenshots/api.png)               |
| Delayed Jobs                            | ![Jobs](documentation/screenshots/jobs.png)             |
| Emails                                  | ![Emails](documentation/screenshots/email.png)          |
| File Uploads                            | ![Files](documentation/screenshots/file-uploads.png)    |
| Stripe Customer Portal Integration      | ![Stripe](documentation/screenshots/stripe-console.png) |

## License

MyTemplate is based on the [Ignite for Flask](https://github.com/Sumukh/Ignite) starter, which is a commercial product. Usage is governed by the original Ignite license. See `LICENSE.md` for details.

## Credits

Design elements from [tabler](https://github.com/tabler/tabler) & Bootstrap 4.

Built off of [Flask Foundation](https://jackstouffer.github.io/Flask-Foundation/) and the [bootstrapy project](https://github.com/kirang89/bootstrapy)

### Extra Reading

Only building out an API using Flask?

- Use [create-flask-api](https://github.com/Sumukh/create-flask-api)

**Course: [Fullstack Flask: Build a SaaS using Python and Flask](https://www.newline.co/fullstack-flask/)**

Best practices List:

- [Larger Applications With Flask](http://flask.pocoo.org/docs/patterns/packages/).
- [Creating Websites With Flask](http://maximebf.com/blog/2012/10/building-websites-in-python-with-flask/)
- [Getting Bigger With Flask](http://maximebf.com/blog/2012/11/getting-bigger-with-flask/)
- [Miguel Grinberg's Blog](https://blog.miguelgrinberg.com/category/Python)
