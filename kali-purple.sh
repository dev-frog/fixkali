#!/usr/bin/env bash
#
# kali-purple.sh — turn an existing Kali Linux install into "Kali Purple"
#
# Kali Purple is NOT a separate distro. It is:
#   1. A set of defensive-security metapackages (NIST CSF aligned):
#        kali-tools-identify / -protect / -detect / -respond / -recover
#   2. The purple look & feel (kali-themes-purple + purple wallpapers)
#
# This script adds both on top of a normal Kali rolling install. No reinstall.
#
#   Author: dev-frog
#
set -Eeuo pipefail

RED=$'\033[31m'; GREEN=$'\033[32m'; ORANGE=$'\033[33m'
BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; RESET=$'\033[0m'

info()  { echo -e "\n${GREEN} ✔ ${RESET}${1}"; }
warn()  { echo -e "\n${ORANGE} ! ${RESET}${1}"; }
err()   { echo -e "\n${RED} ✗ ${RESET}${1}" >&2; }
die()   { err "$1"; exit 1; }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
check_root() {
    [ "${EUID:-$(id -u)}" -eq 0 ] || die "Run this script as root (sudo $0)."
}

check_distro() {
    if ! grep -qi kali /etc/os-release 2>/dev/null; then
        die "This is not Kali Linux. Aborting."
    fi
}

# The real (non-root) user, so we can theme their desktop session.
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    TARGET_USER="$(logname 2>/dev/null || true)"
fi
TARGET_HOME=""
[ -n "$TARGET_USER" ] && TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
check_sources() {
    local list=/etc/apt/sources.list
    if ! grep -Eq '^\s*deb\s+https?://http\.kali\.org/kali\s+kali-rolling' "$list" 2>/dev/null; then
        warn "Standard Kali rolling repo not found in $list."
        warn "Expected: deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware"
        read -rp "    Add it now? [y/N] " ans
        if [[ "${ans,,}" == "y" ]]; then
            echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" >> "$list"
            info "Repo added."
        fi
    fi
}

system_update() {
    info "Updating package lists..."
    apt-get -y update
    info "Full-upgrading the system (this can take a while)..."
    apt-get -y full-upgrade
    info "Removing packages that are no longer needed..."
    apt-get -y autoremove --purge
}

install_theme() {
    info "Installing the Kali Purple theme and wallpapers..."
    local pkgs=(kali-wallpapers-legacy kali-wallpapers-all)
    if apt-cache show kali-themes-purple >/dev/null 2>&1; then
        pkgs+=(kali-themes-purple)
    else
        warn "kali-themes-purple not in the archive; installing kali-themes (contains the purple variants)."
        pkgs+=(kali-themes)
    fi
    apt-get -y install "${pkgs[@]}"
}

install_soc_tools() {
    cat <<EOF

${MAGENTA}Kali Purple defensive-security toolsets (NIST CSF):${RESET}
  identify  - asset discovery, vuln scanning (nmap, OpenVAS/GVM ...)
  protect   - hardening, IAM, firewalling
  detect    - IDS/NSM (Suricata, Zeek, Arkime, Wireshark ...)
  respond   - IR, forensics, malware analysis
  recover   - backups, recovery tooling

  ${ORANGE}Full set = several GB of downloads and disk.${RESET}
EOF
    read -rp "Install [a]ll toolsets, [d]etect only, or [s]kip? [a/d/s] " choice
    case "${choice,,}" in
        a) apt-get -y install kali-tools-identify kali-tools-protect \
                               kali-tools-detect kali-tools-respond kali-tools-recover ;;
        d) apt-get -y install kali-tools-detect ;;
        *) warn "Skipping toolset install." ;;
    esac
}

refresh_menu() {
    info "Refreshing the Kali application menu..."
    apt-get -y install --reinstall kali-menu || warn "kali-menu reinstall failed (non-fatal)."
}

apply_desktop_theme() {
    if [ -z "$TARGET_USER" ] || [ -z "$TARGET_HOME" ]; then
        warn "Could not determine your desktop user; skipping automatic theme switch."
        warn "Set it manually: Settings > Appearance > 'Kali-Purple-Dark'."
        return
    fi
    if ! command -v xfconf-query >/dev/null 2>&1; then
        warn "xfconf-query not found (not Xfce?); set the theme via your DE's appearance settings."
        return
    fi
    info "Applying 'Kali-Purple-Dark' to ${TARGET_USER}'s Xfce session..."
    run_user() { sudo -u "$TARGET_USER" DISPLAY="${DISPLAY:-:0}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$TARGET_USER")/bus" "$@"; }
    run_user xfconf-query -c xsettings   -p /Net/ThemeName        -s "Kali-Purple-Dark"   2>/dev/null || true
    run_user xfconf-query -c xfwm4       -p /general/theme        -s "Kali-Purple-Dark"   2>/dev/null || true
    run_user xfconf-query -c xsettings   -p /Net/IconThemeName    -s "Flat-Remix-Purple-Dark" 2>/dev/null || true
    warn "Log out and back in for the theme to fully apply."
}

# ---------------------------------------------------------------------------
main() {
    echo -e "${MAGENTA}"
    echo "  ┌────────────────────────────────────────────┐"
    echo "  │   Kali Linux  ->  Kali Purple  converter    │"
    echo "  └────────────────────────────────────────────┘"
    echo -e "${RESET}"

    check_root
    check_distro
    check_sources
    system_update
    install_theme
    install_soc_tools
    refresh_menu
    apply_desktop_theme

    info "Done. Reboot recommended:  sudo reboot"
}

main "$@"
