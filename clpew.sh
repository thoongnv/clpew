#!/usr/bin/env bash
# Required pyenv, virtualenv, virtualenvwrapper installed

# set -x : Display commands and their arguments as they are executed.
# set -v : Display shell input lines as they are read.

# FIXME export variables not work sometimes
echo -e "Import shell environments ..."

export PATH="/home/thoong/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

docker_container=$1
virtual_env=$2

echo -e "Get Python version and packages ..."

version=$(docker exec -it --user=openerp $docker_container sh -c "pew in $virtual_env python -V")
version=`echo $version | cut -d ' ' -f2 | sed 's/\\r//g'`
packages=$(docker exec -it --user=openerp $docker_container sh -c "pew in $virtual_env pip freeze")

requirement=clpew_"$virtual_env"_requirement.txt
truncate -s 0 $requirement
for pkg in $packages; do
    if [[ $pkg != *"=="* ]] || [[ $pkg == *"trobz"* ]] || [[ $pkg == *"remoteoi"* ]] || [[ $pkg == *"emoi"* ]] || [[ $pkg == *"python-apt"* ]] || [[ $pkg == *"apt-xapian-index"* ]]; then
        continue
    fi

    if [[ $version == "2.7.6" ]]; then
        if [[ $pkg == *"python-debian"* ]]; then
            pkg="python-debian"
        fi

        if [[ $pkg == *"pygobject"* ]]; then
            pkg="pygobject"
        fi

        if [[ $pkg == *"apt-xapian-index"* ]]; then
            pkg="apt-xapian-index"
        fi

        if [[ $pkg == *"requests"* ]]; then
            pkg="requests"
        fi
    fi

    if [[ $pkg == *"psycopg2"* ]]; then
        pkg="psycopg2"
    fi

    echo -e $pkg >> $requirement
done

if [ $version == "Environment" ]; then
    echo -e "Not found virtual environment $virtual_env"
    exit 1
fi

pyenv_exist=false
virtual_env_exist=false
virtual_env_version="$version/envs/$virtual_env"
for env in `pyenv versions`; do
    if [ $env == $virtual_env_version ]; then
        virtual_env_exist=true
    fi
    if [ $env == $version ]; then
        pyenv_exist=true
    fi
done

if [ $pyenv_exist == "false" ]; then
    echo -e "Install pyenv version $version ..."
    pyenv install $version
fi

pyenv local $version
if [ $virtual_env_exist == "false" ]; then
    echo -e "Install virtual environment $virtual_env ..."
    pyenv virtualenv $version $virtual_env
fi

pyenv local $virtual_env_version
echo -e "Install Python packages ..."
pip install -r $requirement

pyenv local system
