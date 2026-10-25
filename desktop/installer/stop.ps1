# Stops the Loadline APS local server.
try { Invoke-WebRequest 'http://localhost:8765/__stop' -UseBasicParsing -TimeoutSec 2 | Out-Null } catch {}
