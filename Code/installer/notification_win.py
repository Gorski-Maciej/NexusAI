"""
notification_win.py — Windows native toast notifications.

Uses winrt (Python for Windows Runtime) to show native Windows 10/11
toast notifications. Falls back to ctypes if winrt is not available.
"""

from __future__ import annotations

import logging
import platform
import sys

logger = logging.getLogger("nexus.installer.notification")

# ── Check if running on Windows ─────────────────────────────────────────────

_IS_WINDOWS = platform.system() == "Windows" or sys.platform == "win32"


def _show_toast_fallback(title: str, message: str, app_name: str = "NexusAI") -> None:
    """Fallback using ctypes to show a simple Windows balloon notification."""
    try:
        import ctypes
        from ctypes import wintypes

        # Use Win32 API to show a notification
        ctypes.windll.user32.MessageBoxW(
            0,
            f"{message}\n\n(Click OK to dismiss)",
            f"{app_name} — {title}",
            0x40 | 0x1000,  # MB_ICONASTERISK | MB_SYSTEMMODAL
        )
    except Exception as e:
        logger.debug("Fallback notification failed: %s", e)


def _show_toast_winrt(title: str, message: str, app_name: str = "NexusAI") -> bool:
    """Show native Windows toast notification using winrt."""
    try:
        from winrt.windows.ui.notifications import (
            ToastNotificationManager,
            ToastNotification,
            ToastTemplateType,
        )
        from winrt.windows.data.xml.dom import XmlDocument

        # Create a toast template
        template = ToastNotificationManager.get_template_content(
            ToastTemplateType.TOAST_TEXT02
        )
        xml = template.get_xml()

        # Parse and modify XML
        doc = XmlDocument()
        doc.load_xml(xml)

        # Set title text
        text_nodes = doc.get_elements_by_tag_name("text")
        text_nodes.item(0).append_child(doc.create_text_node(title))
        if text_nodes.length > 1:
            text_nodes.item(1).append_child(doc.create_text_node(message))

        # Create and show notification
        notification = ToastNotification(doc)
        notifier = ToastNotificationManager.create_toast_notifier(app_name)
        notifier.show(notification)
        return True

    except ImportError:
        logger.debug("winrt not available for native toasts")
        return False
    except Exception as e:
        logger.debug("winrt toast failed: %s", e)
        return False


# ── Public API ──────────────────────────────────────────────────────────────

def show_notification(
    title: str,
    message: str,
    app_name: str = "NexusAI",
) -> bool:
    """Show a Windows native toast notification.

    Tries winrt first (native Windows 10/11 toasts), falls back to
    simple MessageBox.

    On non-Windows systems, this is a no-op.
    """
    if not _IS_WINDOWS:
        logger.debug("Notifications not supported on this platform")
        return False

    # Try winrt first
    if _show_toast_winrt(title, message, app_name):
        logger.info("Notification shown via winrt: %s — %s", title, message)
        return True

    # Fallback to ctypes/MessageBox
    try:
        _show_toast_fallback(title, message, app_name)
        logger.info("Notification shown via fallback: %s — %s", title, message)
        return True
    except Exception as e:
        logger.warning("Failed to show notification: %s", e)
        return False


def show_download_complete(success_count: int, fail_count: int = 0) -> None:
    """Show a notification when model downloads complete."""
    if fail_count == 0:
        show_notification(
            "Download Complete",
            f"All {success_count} AI models downloaded and verified successfully.\n"
            "NexusAI is ready to use.",
        )
    elif success_count > 0:
        show_notification(
            "Download Partially Complete",
            f"{success_count} model(s) downloaded, but {fail_count} failed.\n"
            "Check your internet connection and try again.",
        )
    else:
        show_notification(
            "Download Failed",
            f"Failed to download {fail_count} AI model(s).\n"
            "Please check your internet connection and restart NexusAI.",
            )


def show_update_available(version: str, release_notes: str) -> None:
    """Show a notification when an update is available."""
    show_notification(
        "Update Available",
        f"NexusAI v{version} is available!\n{release_notes[:100]}...",
    )
