"""One-shot helper to install and start the Windows service.

Run as Administrator:
    python install_service.py
"""
import subprocess
import sys
from pathlib import Path


def main():
    script = Path(__file__).parent / "windows_service.py"
    python = sys.executable

    print("Installing service...")
    subprocess.check_call([python, str(script), "install"])

    print("Setting service to auto-start...")
    subprocess.check_call(
        ["sc", "config", "DownloadManagerDaemon", "start=", "auto"]
    )

    print("Starting service...")
    subprocess.check_call([python, str(script), "start"])

    print("Done. Service 'DownloadManagerDaemon' is running.")


if __name__ == "__main__":
    main()
