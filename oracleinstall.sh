#!/bin/sh

set -e
set -u

PLUGIN_URL="https://labs.consol.de/assets/downloads/nagios/check_oracle_health-3.1.2.2.tar.gz"
PLUGIN_VER=$(echo "$PLUGIN_URL" | sed 's/.*check_oracle_health-\(.*\).tar.gz/\1/')

cat <<- EOF
	#######################################
	#                                     #
	# This is the installer script        #
	# for installing Oracle monitoring    #
	# libraries.                          #
	#                                     #
	# Before you continue, be sure that   #
	# the oracle-basic, sqlplus and devel #
	# are in the same directory as this   #
	# installer script.                   #
	#                                     #
	#######################################
EOF

# get os and version
if which lsb_release &>/dev/null; then
    distro=`lsb_release -si`
    version=`lsb_release -sr`

elif [ -r /etc/redhat-release ]; then
    if rpm -q centos-release; then
        distro=CentOS

    elif rpm -q sl-release; then
        distro=Scientific

    elif rpm -q fedora-release; then
        distro=Fedora

    elif rpm -q redhat-release || rpm -q redhat-release-server; then
        distro=RedHatEnterpriseServer

    fi >/dev/null
    version=`sed 's/.*release \([0-9.]\+\).*/\1/' /etc/redhat-release`
else
    usage_error "Could not determine OS. Please make sure lsb_release is installed."
fi

# get os type
if [ "$distro" = "CentOS" ] || [ "$distro" = "Scientific" ] || [ "$distro" = "Fedora" ] || [ "$distro" = "RedHatEnterpriseServer" ]; then
    ostype="rpm"
else
    ostype="deb"
fi

if [ "$ostype" == "rpm" ]; then
	# repo installs
	yum -y install glibc\* perl-YAML

	# local installs
	yum -y --nogpgcheck localinstall  \
	oracle-instantclient*basic*.rpm   \
	oracle-instantclient*sqlplus*.rpm \
	oracle-instantclient*devel*.rpm
else
	# "$ostype" == "deb"
	# repo installs
	apt-get install -y libc6 libyaml-perl alien

	echo 'Converting RPMs to DEBs for installation. This may take several minutes...'
	echo -ne '(0/3)\r'
	# local installs
	alien -i oracle-instantclient*basic*.rpm >/dev/null
	echo -ne '(1/3)\r'
	alien -i oracle-instantclient*sqlplus*.rpm >/dev/null
	echo -ne '(2/3)\r'
	alien -i oracle-instantclient*devel*.rpm >/dev/null
	echo -ne '(3/3) '
	echo 'Finished installing!'
fi

### SETTING ENVIRONMENT VARIABLES

if arch | grep 64 >/dev/null; then
	client="client64"
else
	client="client"
fi

version=$(echo oracle-instantclient*basic*.rpm | sed 's/.*instantclient\([0-9.]*\).*/\1/')

export ORACLE_HOME="/usr/lib/oracle/$version/$client"
export LD_LIBRARY_PATH="$ORACLE_HOME/lib"

### BEGIN CPAN INSTALL

echo "CPAN may ask you questions. Choose 'No' if it asks if you want to"
echo "do a manual install, unless you have special internet settings."

cpan -i DBI

if [ "$ostype" == "rpm" ]; then
	# Check distro version
	ver=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
	ver=${ver:0:1}

	if [ "$ver" = "7" ] || [ "$ver" = "7Server" ]; then
	    if [ $version = 12.1 ]; then
	            cp -p /usr/share/oracle/$version/$client/demo/demo.mk /usr/share/oracle/$version/$client/demo.mk
	    fi
	fi
fi


# CPAN's newest DBD::Oracle module doesn't work with the plugin. Now need to source install the older version.

wget http://search.cpan.org/CPAN/authors/id/P/PY/PYTHIAN/DBD-Oracle-1.74.tar.gz 
tar -xvzf DBD-Oracle-1.74.tar.gz 
cd DBD-Oracle-1.74 
perl Makefile.PL -l 
make && make test 
make install

# BEGIN SOURCE INSTALL :(

echo "Beginning source install..."
wget "$PLUGIN_URL"
tar xvf check_oracle_health-$PLUGIN_VER.tar.gz

(
	cd check_oracle_health-$PLUGIN_VER
	./configure
	make && make install
)

# DO MKDIR

mkdir /var/tmp/check_oracle_health
chown -R nagios /var/tmp/check_oracle_health

echo "ORACLE_HOME=/usr/lib/oracle/$version/$client"
echo "LD_LIBRARY_PATH=/usr/lib/oracle/$version/$client/lib"
