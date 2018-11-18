#!/bin/bash
set -e

is_root() {
    if [ "$EUID" -ne 0 ];then
        return 1
    else
        return 0
    fi
}

architecture() {
    case `uname -m` in
        x86_64)
            echo x86_64
            ;;
        i686 | i386)
            echo i686
            ;;
        #Probably expand out more options for arm and aarch64
        armv7*)
            echo arm32
            ;;
        aarch64)
            echo arm64
            ;;
        *)
            error "unknown architecture detected"
            ;;
    esac
}

get_os() {
    # TODO: Check to see what cygwin and similar would return when using "uname -o"
    case `uname -o` in
        Msys)
            echo Windows
            ;;
        Android)
            echo Android
            ;;
        *)
            echo $(uname -s)
            ;;
    esac
}

system() {
    case $(get_os) in
        GNU/Linux)
            echo linux
            ;;
        Android)
            echo android
            ;;
        Darwin)
            echo apple
            ;;
        Windows)
            echo pc-windows-msvc
            ;;
        *)
            error "machine os type is not supported"
            ;;
    esac
}

get_latest_version() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

get_url() {
    local arch=$(architecture)
    local os=$(system)
    #Maybe instead of getting the latest version, we could get the latest stable release instead to reduce the chance of
    #exposed bugs being sent to users
    local version=$(get_latest_version "foundpatterns/torchbear")
    #TODO: Use github api to get the uri for the download instead.
    echo "https://github.com/foundpatterns/torchbear/releases/download/${version}/torchbear-${version}-${arch}-${os}-stable.zip"
}

download_and_extract() {
    if [ -f $1 ]; then
        error "Path or directory does not exist."
    fi

    if [ -x "$(command -v curl)" ]; then
        curl -L $(get_url) -o temp.zip
        unzip -o temp.zip -d $1
        rm temp.zip
    else
        error "Curl is not installed. Please install curl. If curl is installed, check your path and try again"
    fi

}

#TODO: Add a simple check to see if path already
set_path() {
    if [[ "$(system)" == *"windows"* ]]; then
        if [[ "$PATH" != *"torchbear"* ]]; then
            setx PATH $HOME/.bin/:$PATH
        fi
    fi
}

install() {
    echo System Type: $(get_os)

    if [ -f "/usr/local/bin/torchbear" ] || [ -f "$HOME/.bin/torchbear.exe" ] || [ -f "/data/data/com.termux/files/usr/bin/torchbear" ] || [ ! -x $(command -v torchbear) ]; then
	    #TODO: Give user the an option to upgrade if they are running the installer to upgrade.
        error "Torchbear is already installed."
    fi

    case $(system) in
        linux | apple)
            echo Downloading torchbear
            if is_root; then
                download_and_extract "/usr/local/bin"
            else
                error Please run as root
            fi
            ;;
        android)
            echo Downloading torchbear
            download_and_extract "/data/data/com.termux/files/usr/bin"
            ;;
        *windows*)
            echo Downloading torchbear
            if [ ! -d "$HOME/.bin" ]; then
                mkdir "$HOME/.bin"
            fi
            download_and_extract "$HOME/.bin"
            set_path
            ;;
        *)
            error "System is not supported at this time"
            ;;
    esac

    if [ -x $(command -v torchbear) ] || [ -f "$HOME/.bin/torchbear.exe" ]; then
        echo Torchbear has been installed.
    fi
}

error() { echo "$*" 1>&2 ; exit 1; }

install
