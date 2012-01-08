#!/bin/bash

#
# This script installs and configures couchdb on a fresh Amazon Linux AMI instance.
#
# Must be run with root privileges
#

export BUILD_DIR="$PWD"

# install gem dependencies
yum -y install gcc gcc-c++ libtool curl-devel ruby-rdoc zlib-devel openssl-devel make automake rubygems perl git-core
gem install rake --no-ri --no-rdoc

if [ ! -e "/usr/local/bin/couchdb" ]
then

  if [ ! -d "$BUILD_DIR/build-couchdb" ]
  then
    # get build-couch code
    git clone git://github.com/neuhausler/build-couchdb.git
    cd $BUILD_DIR/build-couchdb/
    git submodule init
    git submodule update
  fi

  # run build-couch
  cd $BUILD_DIR/build-couchdb/
  rake git="git://git.apache.org/couchdb.git tags/1.1.1" otp_keep="*" install=/usr/local
fi

# install our .ini
cat << 'EOF' > /usr/local/etc/couchdb/local.ini
[couchdb]
delayed_commits = false

[httpd]
port = 5984
bind_address = 0.0.0.0
socket_options = [{recbuf, 262144}, {sndbuf, 262144}, {nodelay, true}]
WWW-Authenticate = Basic realm="administrator"

[couch_httpd_auth]
require_valid_user = true

[log]
level = error

[admins]
EOF

# generate & set the initial password
export ADMIN_PASSWORD=`mkpasswd`
echo "admin = ${ADMIN_PASSWORD}" >> /usr/local/etc/couchdb/local.ini

if [ ! -e "/etc/logrotate.d/couchdb" ]
then
  # add couch.log to logrotate
  ln -s /usr/local/etc/logrotate.d/couchdb /etc/logrotate.d/
  # change to daily rotation
  sed -e s/weekly/daily/g -i /usr/local/etc/logrotate.d/couchdb
  #logrotate -v -f /etc/logrotate.d/couchdb 
fi

# add couchdb user
adduser --system --home /usr/local/var/lib/couchdb -M --shell /bin/bash --comment "CouchDB" couchdb

# change file ownership
chown -R couchdb:couchdb /usr/local/etc/couchdb /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb

# add couchdb to init.d
ln -s /usr/local/etc/rc.d/couchdb /etc/init.d/couchdb

# done!
echo
echo
echo "Installation complete!"
echo "Couchdb admin password was set to: ${ADMIN_PASSWORD}"
echo
echo "Couchdb is ready to start. Run:"
echo "    sudo service couchdb start"

