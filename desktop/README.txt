Loadline APS for Windows

Install
1. Unzip this folder anywhere.
2. Double-click "Install Loadline.cmd".
   If Windows shows "Windows protected your PC", click More info, then Run anyway.
3. Answer Y or N when it asks whether to start the Loadline server with Windows.

When it finishes, Loadline APS opens in its own window, and you get:
- a "Loadline APS" shortcut on the desktop
- Start menu > Loadline: Loadline APS, Stop Loadline server, Uninstall Loadline
- an entry in Settings > Apps, where you can uninstall it

How it runs
- Installed for your Windows user in %LOCALAPPDATA%\Programs\Loadline. No administrator rights needed.
- A small local web server hosts it on this PC at http://localhost:8765 (only this PC can open it).
- It opens in Microsoft Edge (or Chrome) as an app window, without tabs or an address bar.

Updates
- Each time you open Loadline it checks GitHub (lokeshnegi07-bot/LoadlineAPS, main branch) for a newer version
  and downloads it in the background. The new version shows the next time you open Loadline.
- Your data stays: it is kept in the browser, not in the program files.

Sign in
  Planner   planner / Planner@123
  Purchase  buyer   / Buyer@123
  WMS       stores  / Stores@123
  Admin     admin   / Admin@123
