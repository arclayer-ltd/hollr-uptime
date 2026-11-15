# hollr-uptime

Checks https://hollr.space from GitHub every 10 minutes: the home page, the widget script,
the status and sign-in pages, the API, the www redirect and the TLS certificate (at least 14 days left).

When a check fails 3 times in a row the run fails, GitHub emails the workflow owner, and an issue
labelled `down` is opened. The issue closes itself on the next good run.

Test the alert: Actions → uptime → Run workflow → tick "Fail on purpose".
