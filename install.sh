#!/bin/bash
set -euo pipefail
export LC_ALL=C
umask 022

themes_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/themes" && pwd -P)
theme=/usr/share/sddm/themes/mattino
conf=/etc/sddm.conf.d/zzzz-mattino.conf
lock_dir=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
lock_qml=$lock_dir/LockScreen.qml
lock_original=$lock_qml.mattino-original
lock_assets=$lock_dir/mattino
marker=$theme/.mattino-theme

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

effective_sddm() {
    local files=(/usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf /etc/sddm.conf)
    local file existing=()
    for file in "${files[@]}"; do
        [[ ! -f $file ]] || existing+=("$file")
    done
    if (( ${#existing[@]} )); then
        awk -v key="$1" '
            /^[[:space:]]*\[/ {
                section = $0
                sub(/^[[:space:]]*\[/, "", section)
                sub(/\].*$/, "", section)
            }
            section == "Theme" && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
                value = $0
                sub(/^[^=]*=[[:space:]]*/, "", value)
                sub(/[[:space:]]+$/, "", value)
            }
            END { if (value != "") print value }
        ' "${existing[@]}"
    fi
}

check() {
    local current
    current=$(effective_sddm Current)
    printf 'Configured SDDM theme: %s\n' "${current:-distribution default}"
    if [[ -f $lock_original && -f $lock_qml &&
          $(readlink -- "$lock_assets" || :) == "$theme/mattino" ]] &&
        grep -Fq 'import "mattino" as Mattino' "$lock_qml"; then
        printf 'Plasma lock screen: Jonio Lockscreen\n'
    else
        printf 'Plasma lock screen: shell default\n'
        return 1
    fi
    [[ $current == mattino && -f $marker && -f $theme/Main.qml ]]
}

install_theme() {
    local workspace locker theme_dir
    workspace=$(dpkg-query -W -f='${Version}' plasma-workspace)
    locker=$(dpkg-query -W -f='${Version}' libkscreenlocker6)
    [[ $workspace == *6.3.6-* && ( $locker == *6.3.5-* || $locker == *6.3.6-* ) ]] ||
        fail "Unsupported package versions: plasma-workspace $workspace, libkscreenlocker6 $locker."
    command -v sddm-greeter-qt6 >/dev/null || fail 'The SDDM Qt 6 greeter is missing.'
    theme_dir=$(effective_sddm ThemeDir)
    [[ -z $theme_dir || $theme_dir == "$(dirname -- "$theme")" ]] ||
        fail "SDDM uses a custom theme directory: $theme_dir."
    if [[ -f /etc/sddm.conf ]] &&
        awk '/^[[:space:]]*\[/ { s = $0 } s ~ /^[[:space:]]*\[Theme\]/ && /^[[:space:]]*Current[[:space:]]*=/ { found = 1 } END { exit !found }' /etc/sddm.conf; then
        fail 'Theme.Current in /etc/sddm.conf takes precedence over the Jonio configuration.'
    fi
    [[ ! -e $theme || -f $marker ]] || fail "The path $theme is already in use."
    [[ ! -e $conf || -f $marker ]] || fail "The file $conf already exists."
    if [[ -e $lock_assets || -L $lock_assets ]]; then
        [[ $(readlink -- "$lock_assets" || :) == "$theme/mattino" ]] ||
            fail "The path $lock_assets is already in use."
    fi

    local diverted
    diverted=$(dpkg-divert --truename "$lock_qml")
    case "$diverted" in
        "$lock_qml")
            [[ -f $lock_qml && ! -e $lock_original ]] || fail 'The original Plasma lock screen is missing or its backup path is already in use.'
            ;;
        "$lock_original")
            [[ -f $lock_original && $(dpkg-divert --listpackage "$lock_qml") == LOCAL ]] ||
                fail 'Could not verify the original Plasma lock screen backup.'
            ;;
        *)
            fail "The Plasma lock screen already has a dpkg diversion: $diverted."
            ;;
    esac

    local files=(
        jonio-display-manager/Main.qml jonio-display-manager/metadata.desktop
        jonio-display-manager/theme.conf jonio-display-manager/preview.png
        jonio-lockscreen/LockScreen.qml shared/Scene.qml shared/Field.qml shared/Action.qml shared/Mattino.png
        shared/qmldir shared/UnlockState.qml shared/PickerMenu.qml shared/PickerOption.qml
        shared/icons/badge.svg shared/icons/lock.svg shared/icons/chevron.svg shared/icons/power.svg
        shared/icons/keyboard.svg shared/icons/session.svg shared/icons/switch.svg
        shared/icons/reboot.svg shared/icons/stop.svg
    )
    local file
    for file in "${files[@]}"; do
        [[ -f $themes_dir/$file ]] || fail "Missing theme file: $file."
    done

    install -d -m 0755 -- "$theme" "$theme/mattino/icons"
    install -m 0644 /dev/null "$marker"
    for file in "${files[@]}"; do
        case "$file" in
            jonio-display-manager/*) install -m 0644 -- "$themes_dir/$file" "$theme/${file#jonio-display-manager/}" ;;
            shared/*) install -m 0644 -- "$themes_dir/$file" "$theme/mattino/${file#shared/}" ;;
        esac
    done

    ln -sfnT -- "$theme/mattino" "$lock_assets"
    local lock_tmp
    lock_tmp=$(mktemp -- "$lock_dir/.mattino.XXXXXX")
    install -m 0644 -- "$themes_dir/jonio-lockscreen/LockScreen.qml" "$lock_tmp"
    if [[ $diverted == "$lock_qml" ]]; then
        dpkg-divert --local --rename --divert "$lock_original" --add "$lock_qml"
    fi
    if ! mv -Tf -- "$lock_tmp" "$lock_qml"; then
        if [[ $diverted == "$lock_qml" ]]; then
            dpkg-divert --local --rename --divert "$lock_original" --remove "$lock_qml"
        fi
        fail 'Failed to install LockScreen.qml.'
    fi

    local conf_tmp
    install -d -m 0755 -- "$(dirname -- "$conf")"
    conf_tmp=$(mktemp -- /etc/sddm.conf.d/.mattino.XXXXXX)
    printf '[Theme]\nCurrent=mattino\n' > "$conf_tmp"
    chmod 0644 "$conf_tmp"
    mv -Tf -- "$conf_tmp" "$conf"
    check || fail 'Unable to verify the theme configuration.'
}

remove_theme() {
    [[ -f $marker ]] || fail 'No Jonio installation found.'
    if [[ $(dpkg-divert --truename "$lock_qml") == "$lock_original" ]]; then
        [[ -f $lock_original ]] || fail 'The original Plasma lock screen backup is missing.'
        local rollback
        rollback=$(mktemp -d -- "$lock_dir/.mattino-restore.XXXXXX")
        if [[ -e $lock_qml ]]; then
            mv -T -- "$lock_qml" "$rollback/LockScreen.qml"
        fi
        if ! dpkg-divert --local --rename --divert "$lock_original" --remove "$lock_qml"; then
            if [[ -e $rollback/LockScreen.qml ]]; then
                mv -T -- "$rollback/LockScreen.qml" "$lock_qml"
            fi
            rmdir -- "$rollback"
            fail 'Failed to restore the original Plasma lock screen.'
        fi
        rm -f -- "$rollback/LockScreen.qml"
        rmdir -- "$rollback"
    fi
    if [[ $(readlink -- "$lock_assets" || :) == "$theme/mattino" ]]; then
        rm -- "$lock_assets"
    fi
    rm -f -- "$conf"
    rm -r -- "$theme"
    printf 'Restored the original Plasma lock screen and the previous SDDM configuration.\n'
}

case "${1:---install}" in
    --check)
        check
        ;;
    --install|--remove)
        (( EUID == 0 )) || fail 'Run this command with sudo to change system themes.'
        exec 9>/run/lock/mattino-theme.lock
        flock 9
        if [[ ${1:---install} == --remove ]]; then
            remove_theme
        else
            install_theme
        fi
        ;;
    *)
        fail 'Usage: install.sh [--install|--check|--remove]'
        ;;
esac
