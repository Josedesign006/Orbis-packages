# Orbis — Downloads

Official download packages for **Orbis**.

## Download (latest: v0.6.2)

| Platform | Download |
|---|---|
| 🍎 macOS — Apple Silicon (M1/M2/M3/M4) | [Orbis-macOS-AppleSilicon-arm64.dmg](https://github.com/Josedesign006/Orbis-packages/releases/download/v0.6.2/Orbis-macOS-AppleSilicon-arm64.dmg) |
| 🍎 macOS — Intel | [Orbis-macOS-Intel-x64.dmg](https://github.com/Josedesign006/Orbis-packages/releases/download/v0.6.2/Orbis-macOS-Intel-x64.dmg) |
| 🪟 Windows — x64 | [Orbis-Windows-Setup-x64.exe](https://github.com/Josedesign006/Orbis-packages/releases/download/v0.6.2/Orbis-Windows-Setup-x64.exe) |

> These links point to a **specific version** (updated on every release). Version-pinned URLs avoid the browser-cache problem that `…/releases/latest/download/…` has — that URL never changes between releases, so browsers keep serving the old cached installer.

You can also browse every version on the [Releases page](https://github.com/Josedesign006/Orbis-packages/releases).

## Install notes

- **macOS** — the macOS builds are **code-signed and notarized by Apple**, so they install without security warnings. Pick the build that matches your chip (Apple Silicon vs Intel), open the `.dmg`, and drag **Orbis** to Applications.
- **Windows** — the Windows installer is not yet code-signed, so SmartScreen may appear → **More info** → **Run anyway**. The installer installs per-user (no admin required).

## Verify your download (optional)

Compare the SHA-256 of your downloaded file against [`SHA256SUMS.txt`](./SHA256SUMS.txt).

```bash
# macOS / Linux
shasum -a 256 <downloaded-file>

# Windows (PowerShell)
Get-FileHash <downloaded-file> -Algorithm SHA256
```
