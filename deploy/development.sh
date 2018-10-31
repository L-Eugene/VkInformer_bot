#!/usr/bin/env bash

cat >/tmp/upgrade_script_dbg.sh <<EOF
  # UPDATE SOURCE
  cd $VK_INFORMER_DEBUG_PATH
  git pull

  # UPDATE GEMSET
  cd $VK_INFORMER_DEBUG_BOTSERVER_PATH
  rvm use $VK_INFORMER_DEBUG_RVM
  bundle install
  bundle update

  # RESTART BOTSERVER
  sudo service $BOTSERVER_SERVICE_DEBUG restart
EOF

# Remove old version of upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER '[ -f upgrade_script_dbg.sh ] && rm upgrade_script_dbg.sh'

# Copy upgrade script to server
scp /tmp/upgrade_script_dbg.sh $DEPLOY_USER@$DEPLOY_SERVER:upgrade_script_dbg.sh

# Execute upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER /bin/bash -l -c ./upgrade_script_dbg.sh

# Remove upgrade script from server
ssh $DEPLOY_USER@$DEPLOY_SERVER '[ -f upgrade_script_dbg.sh ] && rm upgrade_script_dbg.sh'
