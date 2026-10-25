# Loadline APS

Public website for Loadline, advanced planning and scheduling for make-to-order manufacturers.

- `index.html`: animated landing page with one widget per workspace (Planner, Purchase, WMS, Admin), a sign-in page for each (`#signin/planner`, `#signin/purchase`, `#signin/wms`, `#signin/admin`) and the product tour video
- `app/index.html`: the Loadline APS app. Opens only after sign-in and shows only the tabs the person's role is given; Admin sees everything plus Users & sign-in, Role access, License, Integrations (ERP and marketing/CRM tool), AI assistant, Branding and Sign-in log. Every screen has an AI assistant with quick tasks and troubleshooting
- `auth.js`: shared sign-in, role access, branding and license check
- `media/`: tour video, captions and cover image

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
