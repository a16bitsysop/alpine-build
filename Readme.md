### Downloading source aports

Use pull-apk-source.sh repo/name, eg:
```bash
pull-apk-source.sh main/lttng-ust
pull-apk-source.sh community/lttng-tools
```

Then add to the git repository before building.

just-build.sh runs "abuild checksum" before building so the package tarball is
downloaded and any new patches have their checksums added before building.
