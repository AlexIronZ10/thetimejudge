# ⚖️ The Time Judge v1.0

**The Time Judge** is a powerful, lightweight activity tracker for Windows built with **AutoHotkey v2**. It helps you monitor your productivity by logging active window usage, providing detailed reports, and allowing granular data filtering.



## ✨ Key Features

* **Real-time Monitoring:** Automatically captures the title of the active window every second.
* **Modular Architecture:** Clean separation between the GUI, the tracking engine, and the data processor.
* **Smart Filtering:** Search through your logs using keywords (e.g., "Chrome", "Excel", "Project X").
* **Global Compatibility:** Export your reports to CSV with universal Excel support (`sep=;` and UTF-8 BOM).
* **Dynamic Interface:** Multi-tabbed GUI with progress bars and system tray integration (Active/Stopped status icons).
* **Data Integrity:** Auto-saves sessions and prevents data loss through incremental JSON logging.

## 🚀 How to Use

1.  **Start Tracking:** Choose a duration (or "Indefinite") and hit **Iniciar**. The icon in your system tray will turn green.
2.  **Analyze Data:** Go to the **Reportes** tab to see your total activity.
3.  **Filter Results:** Use the **Filtros** tab to find specific tasks or applications.
4.  **Export:** Save your results as a `.csv` file to open them in Excel or Google Sheets.

## 📂 Project Structure

* `TheTimeJudge.ahk`: Main entry point and GUI orchestrator.
* `lib/Tracker.ahk`: Core engine for window detection and time calculation.
* `lib/Processor.ahk`: Logic for data consolidation, filtering, and exporting.
* Contains the dynamic status icons (`Green.ico`, `Red.ico`).

## 🛠️ Requirements

* [AutoHotkey v2.0+](https://www.autohotkey.com/)

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---
*Created by Alex IronZ10*
