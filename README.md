# Omeka instance: Dineba

Configuration repo for the **Dineba** Omeka S site. This is not application code — it holds the `.env` recipe, Docker compose override, Georgian i18n sources, and setup notes for use with a fresh clone of [GhentCDH/Omeka-S-Docker](https://github.com/GhentCDH/Omeka-S-Docker).

Custom modules and the Freedom theme live in separate GitHub repos:

| Repo | Role |
|------|------|
| [Omeka-S-module-InternetArchiveInboundSync](https://github.com/c-host/Omeka-S-module-InternetArchiveInboundSync) | IA import |
| [Omeka-S-module-InternetArchiveOutboundSync](https://github.com/c-host/Omeka-S-module-InternetArchiveOutboundSync) | IA publish / push |
| [Omeka-S-module-ContributeEnhancements](https://github.com/c-host/Omeka-S-module-ContributeEnhancements) | Contribute workflow |
| [freedom](https://github.com/c-host/freedom) | Freedom theme fork |

## How this relates to Ghent Docker

[Ghent Omeka-S-Docker](https://github.com/GhentCDH/Omeka-S-Docker) out of the box:

1. Copy `example.env` → `.env` and edit values.
2. Run `docker compose up` (builds the image on first run).
3. Store Omeka data in a **Docker named volume** (`omeka:/volume` in `compose.yaml`) — nothing under `./data/omeka/` on the host.
4. At container start, entrypoint scripts create `database.ini`, **download** modules/themes listed in `OMEKA_S_MODULES` / `OMEKA_S_THEMES`, and optionally **install** core/modules when `OMEKA_S_INSTALL_CORE=1` / `OMEKA_S_INSTALL_MODULES=1`.

**Dineba adds** (via this repo):

- A full `.env` recipe (stock modules + custom ZIP URLs).
- `compose.override.yaml` from `compose.override.example.yaml` — bind-mounts `./data/omeka` onto `/volume` so files are visible on the host, plus a startup hook that installs `ka.mo`.
- Georgian i18n sources under `i18n/`.

You do **not** need to create `data/omeka/config`, `modules`, `themes`, etc. by hand — Ghent’s entrypoint creates and populates them on first boot. The only host path you may prepare yourself is `data/omeka/i18n/` if you want `ka.mo` in place before the first start (see [i18n/README.md](i18n/README.md)).

## Layout on disk

```
~/projects/dineba-omeka/
├── config/                  ← this repo (clone name is arbitrary)
└── ghent-omeka-s-docker/    ← upstream: git clone GhentCDH/Omeka-S-Docker
    ├── .env                 ← copy from config/.env.example (replaces example.env)
    ├── compose.override.yaml  ← copy from config/compose.override.example.yaml (not in upstream)
    └── data/
        ├── db-init/         ← from upstream (optional SQL seed on first DB start)
        └── omeka/           ← created by bind mount; populated at container start
```

Upstream only ships `data/db-init/`. The `data/omeka/` tree exists because **our** compose override maps it to `/volume`.

## First-time setup (new machine)

```bash
mkdir -p ~/projects/dineba-omeka && cd ~/projects/dineba-omeka
git clone https://github.com/c-host/omeka-instance-dineba.git config
git clone https://github.com/GhentCDH/Omeka-S-Docker.git ghent-omeka-s-docker
cp config/.env.example ghent-omeka-s-docker/.env
cp config/compose.override.example.yaml ghent-omeka-s-docker/compose.override.yaml
```

Edit `ghent-omeka-s-docker/.env`:

- Set admin email/password.
- Confirm release ZIP URLs match uploaded GitHub Release assets (see below).
- For a **brand-new** Omeka install (empty database), set `OMEKA_S_INSTALL_CORE=1` and `OMEKA_S_INSTALL_MODULES=1` for the first `docker compose up`, then set both back to `0` (re-runs are safe — install scripts skip when already installed).
- For an **existing** Dineba database restore, keep `OMEKA_S_INSTALL_CORE=0` and `OMEKA_S_INSTALL_MODULES=0`.

Optional — Georgian locale before first start:

```bash
mkdir -p ghent-omeka-s-docker/data/omeka/i18n
cp config/i18n/ka.mo ghent-omeka-s-docker/data/omeka/i18n/ka.mo   # after building ka.mo
```

Start (first run builds the image; may take several minutes):

```bash
cd ghent-omeka-s-docker
docker compose up -d
```

Omeka: [http://localhost:8080](http://localhost:8080) (or `OMEKA_S_EXPOSED_PORT`). PHPMyAdmin and Mailpit use the ports documented in [upstream README](https://github.com/GhentCDH/Omeka-S-Docker#configuration).


## Upgrading modules

Per [Ghent’s module download docs](https://github.com/GhentCDH/Omeka-S-Docker#download-modules-at-startup), modules are downloaded at startup; **existing module directories are not overwritten**. That is normal during migration or when upgrading (remove the module folder first — see below).

## In-place migration (dev bind-mounts → on-disk modules)

Use this only when Dineba already runs with modules bind-mounted from sibling source folders (a local dev pattern, not upstream Ghent).

### 1. Backup

```bash
cd ghent-omeka-s-docker
docker compose exec -T db mariadb-dump -uomeka -pomeka omeka > ~/dineba-omeka-backup-$(date +%Y%m%d).sql
```

### 2. Copy module and theme code into the volume

```bash
docker compose stop omeka
cp -a ../InternetArchiveInboundSync   data/omeka/modules/InternetArchiveInboundSync
cp -a ../InternetArchiveOutboundSync  data/omeka/modules/InternetArchiveOutboundSync
cp -a ../ContributeEnhancements       data/omeka/modules/ContributeEnhancements
cp -a ../freedom-theme                data/omeka/themes/freedom
```

### 3. Remove bind-mounts from compose override

`compose.override.yaml` should match `compose.override.example.yaml` in this repo (data volume + `ka.mo` hook only — **no** `../InternetArchive*` volume lines).

### 4. Update `.env`

- Add custom module and theme ZIP URLs (for future upgrades).
- Add `Internationalisation` to `OMEKA_S_MODULES` if not present.
- Keep `OMEKA_S_INSTALL_CORE=0` and `OMEKA_S_INSTALL_MODULES=0`.

### 5. Georgian locale (`ka.mo`)

See [i18n/README.md](i18n/README.md). Place compiled `ka.mo` at `ghent-omeka-s-docker/data/omeka/i18n/ka.mo`.

### 6. Start and verify

```bash
docker compose up -d
```

Admin → Modules: IA Inbound, IA Outbound, Contribute Enhancements, Internationalisation should remain active. Smoke-test Contribute and IA workflows.

## Language switcher (Dineba)

The [Freedom theme fork](https://github.com/c-host/freedom) can show a language switcher when enabled per site.

1. **Modules →** install and activate **Internationalisation**.
2. **Admin → Settings → Internationalisation** — add site groups (one line per group, space-separated slugs), e.g. `dineba dineba-ka`.
3. **Admin → Sites →** each site → **Settings → Language** — distinct locale per site (`en` / `en_US` for English, `ka` for Georgian).
4. Create **matching pages and navigation** on both sites so the switcher keeps visitors on the equivalent page.
5. **Admin → Sites →** each site → **Theme** → **Configure** → enable **Show language switcher** (off by default).
6. Install `ka.mo` (see i18n/) and configure Internationalisation language files under `data/omeka/files/language/` as needed.

## Security

- Copy `.env.example` to `.env` locally — **do not commit** `.env` (Ghent gitignores `.env`).
- If credentials were ever committed, rotate the admin password and use `git rm --cached .env` before pushing.

## Upgrading a custom module

1. Tag and publish a new GitHub Release with an uploaded zip.
2. Update the tag segment in the ZIP URL in `.env` (zip filename stays the same).
3. `docker compose stop omeka && rm -rf data/omeka/modules/ModuleName`
4. `docker compose up -d`
5. **Admin → Modules → Upgrade**
