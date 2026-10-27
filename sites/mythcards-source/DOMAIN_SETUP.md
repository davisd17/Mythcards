# Public Domain Setup

Authorized and verified 2026-10-25, America/New_York.

Existing Site: `appgprj_6adb2bdbdf948191a2c7e22a1691791c`.
Audience: public, explicitly authorized by the owner.

Both `https://mythcards.io` and `https://www.mythcards.io` serve the current
MythCards site. Sites reports active routing and active SSL for both; browser
checks confirmed actual content over HTTPS. No domain forwarding rule was added.

Cloudflare DNS records:

- A `@` -> `162.159.143.30`, DNS only, TTL Auto.
- A `@` -> `172.66.3.26`, DNS only, TTL Auto.
- CNAME `www` -> `custom-domains.chatgpt.site`, DNS only, TTL Auto.
- TXT ownership verification at `_openai-site-verification` and
  `_openai-site-verification.www` with the exact values returned by Sites.
- TXT certificate validation at `_cf-custom-hostname` and
  `_cf-custom-hostname.www` with the exact values returned by Sites.

The DNS zone was empty before setup. No email records, nameservers, account
security settings or subscriptions were changed. Keep the verification records;
do not replace the returned apex A records with a guessed CNAME or enable another
proxy without checking compatibility with the existing Sites custom-domain route.

Web Analytics beacon injection and reporting were not verified during domain
connection; DNS/HTTPS success does not by itself prove analytics is collecting.
