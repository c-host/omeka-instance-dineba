# Omeka instance: Dineba

Configuration repo for the **Dineba** Omeka S site. This is not application code — it holds the `.env` recipe, Docker compose override, Georgian i18n sources, and setup notes for use with a fresh clone of [GhentCDH/Omeka-S-Docker](https://github.com/GhentCDH/Omeka-S-Docker).

Custom modules and the Freedom theme live in separate GitHub repos:

| Repo | Role |
|------|------|
| [Omeka-S-module-InternetArchiveInboundSync](https://github.com/c-host/Omeka-S-module-InternetArchiveInboundSync) | IA import |
| [Omeka-S-module-InternetArchiveOutboundSync](https://github.com/c-host/Omeka-S-module-InternetArchiveOutboundSync) | IA publish / push |
| [Omeka-S-module-ContributeEnhancements](https://github.com/c-host/Omeka-S-module-ContributeEnhancements) | Contribute workflow |
| [freedom](https://github.com/c-host/freedom) | Freedom theme fork |

## Layout on disk

```
~/projects/dineba-omeka/
├── omeka-instance-dineba/     ← this repo (clone as `config` or any name)
└── ghent-omeka-s-docker/    ← git clone upstream Ghent Docker
    ├── .env                 ← copy from config/.env.example (not committed here)
    ├── compose.override.yaml
    └── data/omeka/          ← persistent Omeka data (gitignored by Ghent)
```

## First-time setup (new machine)

```bash
mkdir -p ~/projects/dineba-omeka && cd ~/projects/dineba-omeka
git clone https://github.com/c-host/omeka-instance-dineba.git config
git clone https://github.com/GhentCDH/Omeka-S-Docker.git ghent-omeka-s-docker
cp config/.env.example ghent-omeka-s-docker/.env
cp config/compose.override.example.yaml ghent-omeka-s-docker/compose.override.yaml
```

Edit `ghent-omeka-s-docker/.env`: set admin email/password, and confirm release ZIP URLs match uploaded GitHub Release assets (see below).

```bash
cd ghent-omeka-s-docker
mkdir -p data/omeka/{config,files,modules,themes,logs,i18n}
docker compose up -d
```

For an **existing** Dineba database, keep `OMEKA_S_INSTALL_CORE=0` and `OMEKA_S_INSTALL_MODULES=0`.

## Release ZIPs (required before ZIP URLs work)

GitHub **tags alone are not enough** — each release needs a **zip asset** uploaded. The top-level folder inside each zip must match Omeka’s directory name:

| Zip asset name | Folder inside zip |
|----------------|-------------------|
| `InternetArchiveInboundSync.zip` | `InternetArchiveInboundSync/` |
| `InternetArchiveOutboundSync.zip` | `InternetArchiveOutboundSync/` |
| `ContributeEnhancements.zip` | `ContributeEnhancements/` |
| `freedom.zip` | `freedom/` |

Build zips from the shared workspace script (see [dev-docs/release-zips.md](../dev-docs/release-zips.md)), upload to each repo’s GitHub Release, then set URLs in `.env`:

```bash
# From your omeka-s workspace (not the instance config repo)
bash scripts/build-release-zips.sh
```

Output: `release-zips/` next to your module clones (when run from the `omeka-s` workspace).

```text
https://github.com/c-host/Omeka-S-module-InternetArchiveInboundSync/releases/download/v1.3.0/InternetArchiveInboundSync.zip
```

If a module directory **already exists** under `data/omeka/modules/`, Ghent Docker skips download — that is normal during migration.

## In-place migration (bind-mount → on-disk modules)

Use this when Dineba already runs with modules bind-mounted from sibling folders.

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
cp -a ../freedom-theme              data/omeka/themes/freedom
```

### 3. Remove bind-mounts from compose override

`compose.override.yaml` should match `compose.override.example.yaml` in this repo (data volume + `ka.mo` hook only — **no** `../InternetArchive*` volume lines).

### 4. Update `.env`

- Add custom module and theme ZIP URLs (for future upgrades).
- Add `Internationalisation` to `OMEKA_S_MODULES` if not present.
- Keep `OMEKA_S_INSTALL_CORE=0` and `OMEKA_S_INSTALL_MODULES=0`.

### 5. Georgian locale (`ka.mo`)

See [i18n/README.md](i18n/README.md). Copy compiled `ka.mo` to `ghent-omeka-s-docker/data/omeka/i18n/ka.mo`.

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

- Copy `.env.example` to `.env` locally — **do not commit** `.env` (it is gitignored).
- If credentials were ever committed, rotate the admin password and use `git rm --cached .env` before pushing.

## Upgrading a custom module

1. Tag and publish a new GitHub Release with an uploaded zip.
2. Update the ZIP URL in `.env`.
3. `docker compose stop omeka && rm -rf data/omeka/modules/ModuleName`
4. `docker compose up -d`
5. **Admin → Modules → Upgrade**
