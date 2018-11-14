#!/usr/bin/env bash

cat >/tmp/upgrade_script.sh <<EOF
  # UPDATE SOURCE
  echo "Updating source from Git"
  cd $VK_INFORMER_PROD_PATH
  git pull

  # UPDATE GEMSET
  echo "Updating bundle"
  cd $VK_INFORMER_PROD_BOTSERVER_PATH
  $VK_INFORMER_PROD_RVM/bundle install --without test
  $VK_INFORMER_PROD_RVM/bundle update

  # UPDATE DATABASE
  cd $VK_INFORMER_PROD_BOTSERVER_PATH/app
  $VK_INFORMER_PROD_RVM/rake vk:db:migrate

  # RESTART BOTSERVER
  echo "Restarting server"
  sudo service $BOTSERVER_SERVICE_PROD restart
EOF

# Remove old version of upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER '[ -f upgrade_script.sh ] && rm upgrade_script.sh'

# Copy upgrade script to server
scp /tmp/upgrade_script.sh $DEPLOY_USER@$DEPLOY_SERVER:upgrade_script.sh

# Execute upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER /bin/bash ./upgrade_script.sh
DEPLOY_STATUS=$?

# Remove upgrade script from server
ssh $DEPLOY_USER@$DEPLOY_SERVER '[ -f upgrade_script.sh ] && rm upgrade_script.sh'

exit $DEPLOY_STATUS