#!/usr/bin/env bash
# Incremental commits for Part IV (Locust, venv, README). Run from repo root.
set -e
cd "$(dirname "$0")/.."

echo "Commit 1: Python/Locust setup"
git add .gitignore requirements.txt
git commit -m "chore: add Python venv to gitignore, requirements.txt for Locust" || true

echo "Commit 2: FastHttpUser and scripts"
git add locustfile_fast.py scripts/run-locust-compare.sh scripts/git-commits-part4.sh
git commit -m "test: add locustfile_fast.py and run-locust-compare.sh (Part IV)" || true

echo "Commit 3: README Part IV and report summary"
git add README.md
git commit -m "docs: update README (Part IV venv, report summary, HttpUser vs FastHttpUser)" || true

echo "Done. Push with: git push origin main"
echo "(Locust_*_Report.html are gitignored; attach separately for submission if needed.)"
