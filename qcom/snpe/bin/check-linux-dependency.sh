#!/bin/bash
#==============================================================================
#
#  Copyright (c) 2020-2021, 2023 Qualcomm Technologies, Inc.
#  All Rights Reserved.
#  Confidential and Proprietary - Qualcomm Technologies, Inc.
#
#==============================================================================

function verify_pkg_installed() {
  echo $(dpkg-query -W --showformat='${Status}\n' $1|grep "install ok installed")
}

function setup_op_package_dependencies() {
  apt-get update
  pkgs_to_check=('libncurses5')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install required packages for op packages"
      fi
    fi
    j=$(( $j +1));
  done
}

function setup_accuracy_debugger_dependencies() {
  apt-get update
  pkgs_to_check=('libgl1')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install required packages for accuracy debugger"
      fi
    fi
    j=$(( $j +1));
  done
}

function setup_netron_dependencies() {
  apt-get update
  pkgs_to_check=('libgtk-3-dev' 'libasound2-dev' 'libnss3' 'git' 'nodejs' 'npm'
  'libgbm-dev' 'desktop-file-utils' 'python3-dev' 'python3-pip' 'python3-setuptools')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install required packages for qnn-netron"
      fi
    fi
    j=$(( $j +1));
  done

  # setup npm
  export npm_config_cache=/tmp/npm/
  npm cache clean -f && npm install -g n && n 14.17.4
  npm i -g npm@6.14.14
}

function setup_clang_9() {
  apt-get update
  pkgs_to_check=('clang-9' 'libc++-9-dev')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
      if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install required packages for clang9"
      fi
    fi
    j=$(( $j +1));
  done
}

function setup_flatbuffers-compiler() {
  apt-get update
  pkgs_to_check=('software-properties-common')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
    fi
    j=$(( $j +1));
  done

  add-apt-repository 'deb http://cz.archive.ubuntu.com/ubuntu focal main universe'
  apt-get update
  apt-get install -y 'flatbuffers-compiler'
  echo "Setup Complete. flatc installed at /usr/bin/flatc"
}

function setup_libflatbuffers-dev() {
  apt-get update
  pkgs_to_check=('software-properties-common')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
    fi
    j=$(( $j +1));
  done

  add-apt-repository 'deb http://cz.archive.ubuntu.com/ubuntu focal main universe'
  apt-get update
  apt-get install -y 'libflatbuffers-dev'
  echo "Setup Complete. libflatbuffers-dev installed."
}

function setup_rename() {
  apt-get update
  pkgs_to_check=('software-properties-common')
  j=0
  while [ $j -lt ${#pkgs_to_check[*]} ]; do
    install_status=$(verify_pkg_installed ${pkgs_to_check[$j]})
    if [ "$install_status" == "" ]; then
      apt-get install -y ${pkgs_to_check[$j]}
    fi
    j=$(( $j +1));
  done

  add-apt-repository 'deb http://cz.archive.ubuntu.com/ubuntu focal main universe'
  apt-get update
  apt-get install -y 'rename'
  echo "Setup Complete. rename installed at /usr/bin/rename"
}

#Linux Package dependencies that are needed for QNN SDK
needed_depends=()
needed_depends+=('flatbuffers-compiler')
needed_depends+=('libflatbuffers-dev')
needed_depends+=('rename')

#Unmet dependencies
need_to_install=()
i=0

setup_op_package_dependencies
setup_accuracy_debugger_dependencies
setup_netron_dependencies
setup_clang_9

while [ $i -lt ${#needed_depends[*]} ]; do
  echo "Checking for ${needed_depends[$i]}: $PKG_INSTALLED"
  case "${needed_depends[$i]}" in
    flatbuffers-compiler )
      PKG_INSTALLED=$(verify_pkg_installed ${needed_depends[$i]})
      if [ "$PKG_INSTALLED" == "" ]; then
        if [ -d /usr/bin/flatc ]; then
          case ":$PATH:" in
            *:/usr/bin/flatc:*) echo "flatc Found: /usr/bin/flatc";;
            *) export PATH=/usr/bin/flatc:$PATH
               echo "flatc Found: /usr/bin/flatc. Added to PATH variable";;
          esac
        else
          echo "No pre-installed ${needed_depends[$i]} is found!!"
          need_to_install+=(${needed_depends[$i]})
        fi
      fi
      ;;
    libflatbuffers-dev )
      PKG_INSTALLED=$(verify_pkg_installed ${needed_depends[$i]})
      if [ "$PKG_INSTALLED" == "" ]; then
        if [ -d /usr/include/flatbuffers ]; then
          echo "libfatbuffers-dev found at /usr/include/flatbuffers"
        else
          echo "No pre-installed ${needed_depends[$i]} is found!!"
          need_to_install+=(${needed_depends[$i]})
        fi
      fi
      ;;
    rename )
      PKG_INSTALLED=$(verify_pkg_installed ${needed_depends[$i]})
      if [ "$PKG_INSTALLED" == "" ]; then
        if [ -d /usr/bin/rename ]; then
          case ":$PATH:" in
            *:/usr/bin/rename:*) echo "rename Found: /usr/bin/rename";;
            *) export PATH=/usr/bin/rename:$PATH
               echo "rename found at /usr/bin/rename"
          esac
        else
          echo "No pre-installed ${needed_depends[$i]} is found!!"
          need_to_install+=(${needed_depends[$i]})
        fi
      fi
      ;;
  esac
  i=$(( $i +1));
done
echo "============================================================="
if [ ${#need_to_install[*]} -ne 0 ]; then
  i=0
  echo "Installing Missing Packages"
  echo "--------------------------------------------------------------"
  while [ $i -lt ${#need_to_install[*]} ]; do
    echo "Setting up Package: ${need_to_install[$i]}"
    case "${need_to_install[$i]}" in
      flatbuffers-compiler )
        setup_flatbuffers-compiler
        ;;
      libflatbuffers-dev )
        setup_libflatbuffers-dev
        ;;
      rename )
        setup_rename
        ;;
    esac
    i=$(( $i +1));
    echo "--------------------------------------------------------------"
  done
else
  echo "All Dependency Packages Found"
fi
echo "Done!!"
