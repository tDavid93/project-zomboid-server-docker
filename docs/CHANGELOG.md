# Changelog

## Gameplay
- Slowed zombie respawn to support long-term communal base building while keeping exploration pressure.

## Mods
- No changes.

## Infrastructure
- Added optional workshop auto-update watcher with grace period, idle-restart, and RCON broadcasts.
- Added optional workshop prefetch on startup to download mods before the server launches.

## Fixes
- Fixed workshop map loading to include B42 `common/` and `42/` map paths so mod spawnpoints load correctly.
- Added a startup case-sensitive path fix for workshop mods to resolve missing `animsets` paths on Linux.
- Added a startup fix to link lowercase `usetreadmillvanilla.xml` and `usebenchpressvanilla.xml` for FWO Treadmill & BenchPress on case-sensitive filesystems.
- Restored B42 backslash-prefixed `Mods` format so mods resolve correctly.
