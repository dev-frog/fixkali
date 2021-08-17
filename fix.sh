#!/bin/bash

RED="$(printf '\033[31m')"  
GREEN="$(printf '\033[32m')"  
ORANGE="$(printf '\033[33m')"  
BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  
CYAN="$(printf '\033[36m')"  
WHITE="$(printf '\033[37m')" 
BLACK="$(printf '\033[30m')"
# bg
REDBG="$(printf '\033[41m')"  
GREENBG="$(printf '\033[42m')"  
ORANGEBG="$(printf '\033[43m')"  
BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  
CYANBG="$(printf '\033[46m')"  
WHITEBG="$(printf '\033[47m')" 
BLACKBG="$(printf '\033[40m')"

RESET="$(printf '\033[37m')"
GBRESET="$(printf '\E[32;46m')"




check_distro() {
    distor=$(uname -a | grep -i -c "kali")
    if [ $distor -ne 1 ]; then
        echo -e "\n $RED 😈 Kali Linux Not detected $RESET  \n";exit
    fi
}


check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo  -e "\n $RED 😱 Script must be run with as root $RESET \n";exit
    fi
}


update() {
    echo -e "\n ✔ $GREEN Updating system using apt update command.... $RESET \n"
    eval apt -y update
}


upgrade() {
    echo -e "\n ✔ $GREEN Upgrading system using apt upgrade command.... $RESET \n"
    eval apt -y upgrade
}

autoremote() {
    echo -e "\n ✔ $GREEN removeing packages that were automatically installed  $RESET \n"
    eval apt autoremote
}

install_chrome() {
    echo -e "\n ✔ $GREEN Installing Chrome Browser  $RESET \n"
    eval wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
    eval dpkg -i /tmp/google-chrome-stable_current_amd64.deb
    rm -f /tmp/google-chrome-stable_current_amd64.deb
}

mingw() {
    echo -e "\n $GREEN Installing mingw for Windows compiler  $RESET \n"
    eval apt -y  install mingw-w64
}


smbconf() {
    check_min=$(cat /etc/samba/smb.conf | grep -c -i "client min protocol")
    check_max=$(cat /etc/samba/smb.conf | grep -c -i "client mxa protocol")

    if [ $check_min -ne 0 ] || [ $check_max -ne 0 ]; then
        echo -e "\n ✔ $ORANGE SMB config is ok  $RESET \n"
    else
        cat /etc/samba/smb.conf | sed 's/\[global\]/\[global\]\n   client min protocol = CORE\n   client max protocol = SMB3\n''/' > /tmp/fix_smbconf.tmp
        cat /tmp/fix_smbconf.tmp > /etc/samba/smb.conf
        rm -f /tmp/fix_smbconf.tmp
        echo -e "\n ✔ $GREEN SMB config is fix  $RESET \n"
    fi
}


install_vscode() {
    if [[ -f /usr/bin/code ]]; then
        echo -e "\n ✔ $ORANGE vscode is already installed  $RESET \n"
    else
        echo -e "\n ✔ $GREEN  installing vscode  $RESET \n"
        eval apt install -y code-oss
    fi 
}

insatll_sublime() {
    echo -e "\n ✔ $GREEN  Insatlling sublime text $RESET \n"
    eval wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    eval sudo apt-get install apt-transport-https
    eval echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    eval apt update 
    eval apt install sublime-text

}

install_atom() {
    if [ -f /usr/bin/atom ]; then
        echo -e "\n ✔ $ORANGE Atom already installed $RESET \n"
    else
      apt_update  && apt_update_complete
      echo -e "\n ✔ $GREEN Insatlling Atom $RESET \n"
      eval wget -qO- https://atom.io/download/deb -O /tmp/atom.deb >/dev/null 2>&1
      eval dpkg -i /tmp/atom.deb >/dev/null 2>&1
      eval rm -f /tmp/atom.deb
      eval apt -y --fix-broken install >/dev/null 2>&1
    fi
}


virtualbox() {
    eval mkdir /tmp/vboxtmp
    eval apt -y reinstall virtualbox-dkms virtualbox-guest-x11
    wget http://download.virtualbox.org/virtualbox/LATEST.TXT -O /tmp/vbox-latest
    vboxver=$(cat /tmp/vbox-latest)
    eval mount /usr/share/virtualbox/VBoxGuestAdditions.iso /tmp/vboxtmp
    eval cp -f /tmp/vboxtmp/VBoxLinuxAdditions.run /tmp/VBoxLinuxAdditions.run
    eval umount /tmp/vboxtmp
    eval rmdir /tmp/vboxtmp
    eval chmod +x /tmp/VBoxLinuxAdditions.run
    eval /tmp/VBoxLinuxAdditions.run install --force
    eval rm -f /tmp/VBoxLinuxAdditions.run
    eval /sbin/rcvboxadd quicksetup all
    echo -e "\n ✔ $GREEN A reboot of your system is required  $RESET \n"
}


# art
asciiart=$(base64 -d <<< "ICAgICAgICAgXC4gICBcLiAgICAgIF9fLC0iLS5fXyAgICAgIC4vICAgLi8KICAgICAgIFwuICAgXGAuICBcYC4tJyIiIF8sPSI9Ll8gIiJgLS4nLyAgLicvICAgLi8KICAgICAgICBcYC4gIFxfYC0nJyAgICAgIF8sPSI9Ll8gICAgICBgYC0nXy8gIC4nLwogICAgICAgICBcIGAtJywtLl8gICBfLiAgXyw9Ij0uXyAgLF8gICBfLi0sYC0nIC8KICAgICAgXC4gL2AsLScsLS5fIiIiICBcIF8sPSI9Ll8gLyAgIiIiXy4tLGAtLCdcIC4vCiAgICAgICBcYC0nICAvICAgIGAtLl8gICIgICAgICAgIiAgXy4tJyAgICBcICBgLScvCiAgICAgICAvKSAgICggICAgICAgICBcICAgICwtLiAgICAvICAgICAgICAgKSAgIChcCiAgICAsLSciICAgICBgLS4gICAgICAgXCAgLyAgIFwgIC8gICAgICAgLi0nICAgICAiYC0sCiAgLCdfLl8gICAgICAgICBgLS5fX19fLyAvICBfICBcIFxfX19fLi0nICAgICAgICAgXy5fYCwKIC8sJyAgIGAuICAgICAgICAgICAgICAgIFxfLyBcXy8gICAgICAgICAgICAgICAgLicgICBgLFwKLycgICAgICAgKSAgICAgICAgICAgICAgICAgIF8gICAgICAgICBkZXYtZnJvZyAoICAgICAgIGBcCiAgICAgICAgLyAgIF8sLSciYC0uICAsKyt8VHx8fFR8KysuICAuLSciYC0sXyAgIFwKICAgICAgIC8gLC0nICAgICAgICBcL3xgfGB8YHwnfCd8J3xcLyAgICAgICAgYC0sIFwKICAgICAgLywnICAgICAgICAgICAgIHwgfCB8IHwgfCB8IHwgICAgICAgICAgICAgYCxcCiAgICAgLycgICAgICAgICAgICAgICBgIHwgfCB8IHwgfCAnICAgICAgICAgICAgICAgYFwKICAgICAgICAgICAgICAgICAgICAgICAgYCB8IHwgfCAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgYCB8ICc=")

banner() {
    echo -e "$MAGENTA $asciiart $RESET"
    echo -e "\n$BLUE Author: dev-frog   email: froghunter.cft@gmail.com"
}


install() {
    update
    upgrade
    autoremote
    virtualbox
    mingw
    smbconf
    install_chrome
    install_vscode
    install_atom
    insatll_sublime
}

banner
check_distro
check_root
install