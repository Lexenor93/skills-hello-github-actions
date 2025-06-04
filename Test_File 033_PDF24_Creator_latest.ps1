name: Test PDF24 Creator Script

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run PowerShell script
        run: |
          pwsh -File 033_PDF24_Creator_latest.ps1
