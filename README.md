# auth-bantculture.com

Minimal Phoenix service for Bantculture IP access control.

It is designed to sit in front of `eirinchan-v1` or beside it, using the same
Postgres table that Eirinchan writes to:

- table: `ip_access_entries`
- columns:
  - `ip`
  - `password`
  - `granted_at`

The service has two jobs:

1. Render `/auth` and record successful grants into `ip_access_entries`.
2. Expose a gate endpoint that checks the caller IP against `ip_access_entries`
   and either allows the request or redirects to auth.

It does not proxy the main site. That part should stay in your front webserver.

## Routes

- `GET /auth`
  - renders the password form
- `POST /auth`
  - validates a password from the shared instance config
  - writes the caller subnet into `ip_access_entries`
  - redirects to the requested target or the configured success URL
- `GET|HEAD|POST /gate`
  - returns `204 No Content` if the caller IP is already allowed
  - otherwise redirects to auth
- `GET /healthz`
  - returns `204 No Content`
- `/*path`
  - direct browser helper route
  - if allowed, redirects to the protected site URL for that path
  - if denied, redirects to auth with a `return_to`

## Runtime configuration

Required:

- `DATABASE_URL`
- `SECRET_KEY_BASE`

Optional:

- `INSTANCE_CONFIG_PATH`
  - defaults to sibling checkout `../eirinchan-v1/var/settings.json`
- `ACCESS_DENIED_LOG_PATH`
  - defaults to `config/../var/access_denied.log`
- `SUCCESS_REDIRECT_URL`
  - defaults to `https://bantculture.com`
  - used as the protected site base URL
- `PUBLIC_AUTH_URL`
  - if set, denied requests redirect there instead of local `/auth`
  - useful when the gate runs on a separate host or path
- `PHX_HOST`
- `PORT`

Passwords are read from the shared instance config:

- `ip_access_passwords`
- `ip_access_auth.title`
- `ip_access_auth.message`

## Shared table contract

This app intentionally does not own the `ip_access_entries` schema.

It expects the same schema Eirinchan uses:

```sql
CREATE TABLE ip_access_entries (
  ip varchar NOT NULL,
  password varchar NULL,
  granted_at timestamp NULL
);
```

That keeps integration natural:

- Eirinchan can continue checking the same allowlist
- this app can continue recording grants into the same table

## Local development

```bash
cd /path/to/auth-bantculture.com
mix setup
mix phx.server
```

By default:

- dev HTTP port: `4000`
- test HTTP port: `4002`
- prod HTTP port: `4003`

The dev and test configs support:

- `AUTH_DATABASE_URL`
- `AUTH_TEST_DATABASE_URL`

and also fall back to values in:

- `~/.config/eirinchan-shared.env`

## Front webserver integration

This app is meant to be combined with a fronting webserver.

Minimal pattern:

1. front webserver checks `/gate`
2. `204` means allow the real site request through
3. redirect means send the client to auth

The catch-all route exists so the service is also usable directly in a browser
while testing.

## Security notes

- only the auth UI is served by this app
- successful grants are stored by subnet, matching the Eirinchan behavior:
  - IPv4: `/24`
  - IPv6: `/48`
- invalid passwords are logged as SHA-256 hashes, not raw text
- throttling is per effective IP via ETS
- return targets are restricted to the configured protected-site origin

## Test

```bash
cd /path/to/auth-bantculture.com
mix test
```
