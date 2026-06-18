@echo off
echo Triggering Appium E2E Workflow...
gh workflow run appium-e2e.yml

echo Triggering Security Vulnerability Workflow...
gh workflow run flutter-security-vulnerability.yml

echo Triggering Load/Performance Workflow...
gh workflow run flutter-load-performance.yml

echo All workflows triggered successfully! Use 'gh run list' to check their status.
pause
