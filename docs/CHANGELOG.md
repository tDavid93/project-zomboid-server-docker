# Changelog

## Gameplay
- Slowed zombie respawn to support long-term communal base building while keeping exploration pressure.

## Mods
- No changes.

## Infrastructure
- Added optional workshop auto-update watcher with grace period, idle-restart, and RCON broadcasts.

## Fixes
- Added a startup case-sensitive path fix for workshop mods to resolve missing `animsets` paths on Linux.
- Added a startup fix to link lowercase `usetreadmillvanilla.xml` and `usebenchpressvanilla.xml` for FWO Treadmill & BenchPress on case-sensitive filesystems.
