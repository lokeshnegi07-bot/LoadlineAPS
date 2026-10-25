# Loadline APS

Public website for Loadline, advanced planning and scheduling for make-to-order manufacturers.

- `index.html`: animated landing page with one widget per workspace (Planner, Purchase, WMS, Admin), a sign-in page for each (`#signin/planner`, `#signin/purchase`, `#signin/wms`, `#signin/admin`) and the product tour video
- `app/index.html`: the Loadline APS app. Opens only after sign-in and shows only the tabs the person's role is given; Admin sees everything plus Users & sign-in, Role access, License, Integrations (ERP and marketing/CRM tool), AI assistant, Branding and Sign-in log. Every screen has an AI assistant with quick tasks and troubleshooting
- `auth.js`: shared sign-in, role access, branding and license check
- `media/`: tour video, captions and cover image

## Sales order, work order, production order

Planner › **Work orders** lists every sales order that has been through MRP with how many bought parts are already in stores. A planner with the work order right creates one work order per sales order (with a tick to confirm if parts are short). Planner › **Production orders** splits each work order into one order per line: Winding, Machining, VPI, Assembly and Testing. The sales order, work order and production orders link to each other on every screen and in the order details.

## With or without ERP

Each customer runs Loadline one of two ways, set in Admin › Integrations:

- **Connected to ERP**: Send to ERP starts the MRP run, WMS syncs stock moves, and work orders and production orders go both ways: made here and sent to ERP, or made in ERP (for example SAP CO01) and pulled in with Sync from ERP, with shop floor status updates.
- **Standalone, no ERP**: Release to Purchase runs MRP inside Loadline, buyers create POs from To buy, stores post stock moves straight away, and work orders and production orders live in Loadline.

ERP integration is also a license feature: a key issued with ERP not included keeps the customer on standalone. The ERP side is simulated in this demo.

## Desktop app for Windows

`desktop/` holds a Windows installer: copy the site files into `desktop/site/`, zip the folder and run `Install Loadline.cmd`. It installs for the current user, hosts the app on the PC at `http://localhost:8765` with a small PowerShell server, opens it in an Edge or Chrome app window, and adds desktop and Start menu shortcuts plus an entry in Settings › Apps. Each time it opens it compares `version.json` on `main` and downloads newer files, so **bump `version.json` with every change merged to `main`**.

## Demo accounts

| Workspace | User name | Password |
|---|---|---|
| Planner | planner | Planner@123 |
| Purchase | buyer | Buyer@123 |
| WMS | stores | Stores@123 |
| Admin | admin | Admin@123 |

## Licensing

Loadline is licensed per named user and per workspace. A license key (`LL1.…`) is signed by the vendor with an ECDSA P-256 key and carries the customer, edition, seats per workspace, issue and expiry dates, a grace period and optionally the customer's site. `auth.js` holds only the public key, so a customer cannot raise their own seats. The admin pastes a new key in Admin › License.

- Only as many people per workspace can be active as the license allows; the first active accounts of a role hold its seats.
- After expiry plus the grace period only admins can sign in, to enter a renewal key.
- Keys are issued with the vendor's License studio, kept outside this repository with the private signing key.

This is a static demo: accounts, passwords (hashed), role access and the license live in the browser's localStorage. A production rollout needs server-side sign-in (for example SSO) and a server that enforces access and seats.

Hosted free on GitHub Pages from the `main` branch.
