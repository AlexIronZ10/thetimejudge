# ⚖️ The Time Judge v1.1.0

**The Time Judge** is a powerful, lightweight activity tracker for Windows built with **AutoHotkey v2**. It helps you monitor your productivity by logging active window usage, providing detailed reports, and allowing granular data filtering.



## ✨ Key Features

* **Real-time Monitoring:** Automatically captures the title of the active window every second.
* **Modular Architecture:** Clean separation between the GUI, the tracking engine, and the data processor.
* **Smart Filtering:** Search through your logs using keywords (e.g., "Chrome", "Excel", "Project X").
* **Enhanced Excel Compatibility:** Native UTF-16 LE export ensures that special characters and accents look perfect in Microsoft Excel across all regions.
* **Dynamic Interface:** Multi-tabbed GUI with progress bars and system tray integration (Active/Stopped status icons).
* **Data Integrity:** Auto-saves sessions and prevents data loss through incremental JSON logging into a dedicated /logs folder.
* **Smart Minimize to Tray:** If tracking is active, minimizing the app hides it to the system tray to stay out of your way. If not, it behaves like a standard window.

## 🚀 How to Use

1.  **Start Tracking:** Choose a duration (or "Indefinite") and hit **Iniciar**. The program will be saved in the system tray and the icon will turn green.
2.  **Analyze Data:** Go to the **Reportes** tab to see your total activity.
3.  **Filter Results:** Use the **Filtros** tab to find specific tasks or applications.
4.  **Export:** Save your results as a `.csv` file to open them in Excel or Google Sheets.
5.  **Pro Tip:** Hover your mouse over the tray icon while tracking to see the current status without opening the app!

## 📂 Project Structure

* `TheTimeJudge.ahk`: Main entry point and GUI orchestrator.
* `lib/Tracker.ahk`: Core engine for window detection and time calculation.
* `lib/Processor.ahk`: Logic for data consolidation, filtering, and exporting.
* `logs/`: Dedicated directory for all your activity records (auto-created).
* Contains the dynamic status icons (`Green.ico`, `Red.ico`).

## 🛠️ Requirements

* [AutoHotkey v2.0+](https://www.autohotkey.com/)

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## ⚠️ Antivirus Note

Some antivirus software (like Windows Defender or Chrome Safe Browsing) may flag the .exe file as a "False Positive".

Why does this happen? > This is a common occurrence with scripts compiled via AutoHotkey. Since the executable contains a script runner, some security engines flag it as "unknown software."

How to fix it:

If Windows Defender blocks the launch, click on "More info" and then "Run anyway".

You can also add the .exe to your antivirus Exclusion List.

For total peace of mind, you can audit the source code in this repository and compile the .exe yourself using Ahk2Exe.

---
*Created by Alex IronZ10*
