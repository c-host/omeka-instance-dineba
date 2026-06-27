# Omeka S i18n (`ka.mo`) — Dineba

This directory contains language files for custom localization.  
In this project, we provide the Georgian (`ka`) translation (`ka.mo`) for Omeka S.

## How to Build or Update `ka.mo`

1. **Edit your `.po` file**  
   Edit or update the translation source (`ka.po`) using a translation editor such as [Poedit](https://poedit.net/) or directly via a text editor.

2. **Compile to `.mo` file**  
   Use the GNU gettext tools to compile the `.po` file into `.mo`:

   ```bash
   msgfmt -o ka.mo ka.po
   ```

   This will create `ka.mo` in this directory.

## How to Use in Docker Environment

- The expected location for Dockerized Omeka S is:  
  `Omeka-S-Docker/data/omeka/i18n/ka.mo`

- After building/updating `ka.mo`, copy the file into the Docker data volume, e.g. from this directory:

   ```bash
   cp ka.mo /path/to/Omeka-S-Docker/data/omeka/i18n/ka.mo
   ```

- On (re)starting the container, the file will be copied into the correct place inside the application (see `compose.override.example.yaml` for details).

## References

- [Omeka S Translation Guide](https://omeka.org/s/docs/developer/translation/)
- [gettext Manual](https://www.gnu.org/software/gettext/manual/)
