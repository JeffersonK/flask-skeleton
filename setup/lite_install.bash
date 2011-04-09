#!/usr/bin/env bash

## Check Operating system ##

# This script assumes Ubuntu directory structure.
# (The directory structure is different for different Linux distributions.)

# function die_without_linux
# {
#     echo "This script works only with Ubuntu Linux and Bash."
#     exit 1
# }

# [[ "$OSTYPE" == "linux-gnu" ]]      || die_without_linux
# [[ $(which lsb_release) != "" ]]    || die_without_linux
# [[ $(lsb_release -i) =~ "Ubuntu" ]] || die_without_linux
# [[ ${SHELL} =~ "bash" ]]            || die_without_linux
# [[ "${BASH_VERSINFO[0]}" -ge "4" ]] || die_without_linux

## Check Python version ##

if [[ $(python -c "import sys; print (2,6) <= sys.version_info < (3,0)") != "True" ]]
then
    echo "Need at least Python 2.6"
    exit 1
fi

## Take website name as command line argument ##

SITE_NAME=$1
shift

if [[ -z "$SITE_NAME" ]]
then
    echo "Usage: $0 SITE_NAME"
    exit 1
fi

ADMIN_EMAIL="admin@$SITE_NAME"

APP_NAME="flask_application"

## Utilities ##

# http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/
txtred=$(tput setaf 1)
txtgreen=$(tput setaf 2)
txtyellow=$(tput setaf 3)
txtreset=$(tput sgr0)
txtunderline=$(tput sgr 0 1)

common_prefix="! "

function info
{
    echo "$txtgreen$common_prefix$@$txtreset"
}

function warning
{
    echo "$txtyellow$common_prefix$@$txtreset"
}

function critical
{
    echo "$txtunderline$txtred$common_prefix$@$txtreset"
    exit 1
}

# /home/foo -> \/home\/foo ... so that sed does not get confused.
HOME_ESCAPED=${HOME//\//\\/}


## Environment ##
# switched to python because gnu readlink is a non-starter on osx
script_path=`python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $0`
BOILERPLATE=`python -c 'import os,sys;print os.path.realpath(sys.argv[1])' $(dirname $script_path)/..`

echo $BOILERPLATE
## Assumptions ##

[[ -f "$BOILERPLATE/$APP_NAME/__init__.py" ]] || critical "$BOILERPLATE/$APP_NAME/__init__.py is missing"

SITE_TOP_DIR="../../$SITE_NAME"

[[ ! -d "$SITE_TOP_DIR" ]] || critical "$SITE_TOP_DIR already present"
mkdir -p $SITE_TOP_DIR/{public,private,log,backup}

SITE_CODE_DIR="$SITE_TOP_DIR/private"
SITE_PUBLIC_DIR="$SITE_TOP_DIR/public"

## Main ##
#set -x

info "Domain name --> $SITE_NAME"


# info "Checking Python environment"
# if [[ -z $(dpkg -l | fgrep -i python-setuptools) ]]
# then
#     sudo apt-get install python-setuptools || critical "Could not install setuptools package"
#     sudo easy_install virtualenv==tip
# fi
# PYENV="$HOME/local/pyenv"
# if [[ ! -d "$PYENV" ]]
# then
#     mkdir -p $HOME/local
#     cd $HOME/local
#     export VIRTUALENV_USE_DISTRIBUTE=1
#     export VIRTUAL_ENV_DISABLE_PROMPT=1
#     virtualenv pyenv
#     source pyenv/bin/activate
#     info "Activating $PYENV python environment in your ~/.bashrc"
#     echo >> "$HOME/.bashrc" && echo "source $PYENV/bin/activate" >> "$HOME/.bashrc"
#     easy_install pip
# fi

info "Cloning flask_boilerplate repository"
git clone $BOILERPLATE $SITE_CODE_DIR || critical "Could not clone $BOILERPLATE git repository"
cd $SITE_CODE_DIR

# info "Installing essential Apache build packages and Python library dependencies"

# # Flask
# pip install Flask || critical "Could not download/install Flask module"

# # Fabric
# pip install Fabric

# mkdir -p "$SITE_CODE_DIR/$APP_NAME"
info "Copying codebase to target app folder"
cp -R $script_path/.. "$SITE_CODE_DIR"
cd "$SITE_CODE_DIR/$APP_NAME"

info "Updating config file"
sed -i -e "s/{SITE_NAME}/$SITE_NAME/g" config.py

info "Updating homepage template"
sed -i -e "s/{SITE_NAME}/$SITE_NAME/g" templates/index.html

info "Generating secret key"
SECRET_KEY=`python -c 'import random; print "".join([random.choice("abcdefghijklmnopqrstuvwxyz0123456789@#$%^&*(-_=+)") for i in range(50)])'`
sed -i -e "s/{SECRET_KEY}/$SECRET_KEY/g" -e "s/{SITE_NAME}/$SITE_NAME/g" "config.py" || critical "Could not fill $APP_NAME/config.py"

cd "$SITE_CODE_DIR/setup"

info "Updating the fabfile"
cd "$SITE_CODE_DIR"
sed -i -e "s/{SITE_NAME}/$SITE_NAME/g"  "fabfile.py" || critical "Could not fill fabfile.py"

info "Fetching submodules"
bash $SITE_CODE_DIR/setup/copy_html5.bash $SITE_CODE_DIR

info "DONE"

info "Start adding your actual website code to $SITE_CODE_DIR/$APP_NAME/controllers/frontend.py and see the changes live on $SITE_NAME !"
info "You can 'git clone' the repo from $SITE_CODE_DIR/$APP_NAME to your local box, make changes, and then run 'fab deploy' to update the site!"
#set +x

