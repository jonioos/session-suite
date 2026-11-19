# Installation on Debian 13

## Requirements

- Debian 13 with the SDDM Qt 6 greeter (`sddm-greeter-qt6`).
- Plasma Workspace 6.3.6 and KScreenLocker 6.3.5 or 6.3.6.

## Install and verify

Run these commands from the repository root.

```sh
sudo ./install.sh --install
./install.sh --check
```

The script installs both themes and keeps the current session running. Jonio Lockscreen appears the next time you lock your screen. Jonio Display Manager appears the next time SDDM opens its greeter, such as after you sign out.

SDDM uses the internal theme ID `mattino` so the installer can update an existing Mattino installation. Plasma loads its theme from the shell package. The script uses `dpkg-divert` to preserve the original `LockScreen.qml`. Both screens use native authentication.

## Preview SDDM

Run the Qt 6 greeter in test mode from the repository root.

```sh
sddm-greeter-qt6 --test-mode --theme "$PWD/themes/jonio-display-manager"
```

Power controls may be disabled in test mode. [Preview the SDDM user menu](previews/sddm-user-menu.png).

## Restore the original themes

```sh
sudo ./install.sh --remove
```

The script restores the original Plasma lock screen and the previous SDDM theme. Restore the original themes before upgrading to a Plasma version outside the supported range.
