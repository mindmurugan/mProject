"""Windows Service wrapper for the download manager daemon.

Install:   python windows_service.py install
Start:     python windows_service.py start
Stop:      python windows_service.py stop
Remove:    python windows_service.py remove
Debug run: python windows_service.py debug
"""
from __future__ import annotations

import subprocess
import sys
import threading

SERVICE_NAME = "DownloadManagerDaemon"
SERVICE_DISPLAY = "Download Manager Daemon"
SERVICE_DESC = "FastAPI download manager using yt-dlp and aria2c"

try:
    import win32service
    import win32serviceutil
    import win32event
    import servicemanager

    class DownloadManagerService(win32serviceutil.ServiceFramework):
        _svc_name_ = SERVICE_NAME
        _svc_display_name_ = SERVICE_DISPLAY
        _svc_description_ = SERVICE_DESC

        def __init__(self, args):
            super().__init__(args)
            self._stop_event = win32event.CreateEvent(None, 0, 0, None)
            self._proc: subprocess.Popen | None = None

        def SvcStop(self):
            self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
            win32event.SetEvent(self._stop_event)
            if self._proc:
                self._proc.terminate()

        def SvcDoRun(self):
            servicemanager.LogMsg(
                servicemanager.EVENTLOG_INFORMATION_TYPE,
                servicemanager.PYS_SERVICE_STARTED,
                (self._svc_name_, ""),
            )
            self._run()

        def _run(self):
            import os
            from pathlib import Path

            daemon_py = Path(__file__).parent / "main.py"
            python = sys.executable

            self._proc = subprocess.Popen(
                [python, str(daemon_py)],
                cwd=str(daemon_py.parent),
            )
            # Wait until stop event is fired
            win32event.WaitForSingleObject(self._stop_event, win32event.INFINITE)
            if self._proc.poll() is None:
                self._proc.terminate()
                self._proc.wait()

    def main():
        if len(sys.argv) == 1:
            servicemanager.Initialize()
            servicemanager.PrepareToHostSingle(DownloadManagerService)
            servicemanager.StartServiceCtrlDispatcher()
        else:
            win32serviceutil.HandleCommandLine(DownloadManagerService)

except ImportError:
    # Non-Windows / pywin32 not installed — provide a plain runner for dev
    def main():  # type: ignore[misc]
        import uvicorn
        from config import settings

        print(
            "pywin32 not available; running daemon directly (not as Windows service)."
        )
        uvicorn.run(
            "main:app",
            host=settings.host,
            port=settings.port,
        )


if __name__ == "__main__":
    main()
