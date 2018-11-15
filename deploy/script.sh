#!/usr/bin/env bash

if [  "$1" = "production" ]; then
  VK_FILE_NAME="upgrade_script.sh"
  VK_BOT_PATH=$VK_INFORMER_PROD_PATH
  VK_BOTSERVER_PATH=$VK_INFORMER_PROD_BOTSERVER_PATH
  VK_RVM_WRAPPER=$VK_INFORMER_PROD_RVM
  VK_SERVICE_NAME=$BOTSERVER_SERVICE_PROD
elif [  "$1" = "development" ]; then
  VK_FILE_NAME="upgrade_script_dbg.sh"
  VK_BOT_PATH=$VK_INFORMER_DEBUG_PATH
  VK_BOTSERVER_PATH=$VK_INFORMER_DEBUG_BOTSERVER_PATH
  VK_RVM_WRAPPER=$VK_INFORMER_DEBUG_RVM
  VK_SERVICE_NAME=$BOTSERVER_SERVICE_DEBUG
else
  echo "Invalid argument"
  exit 2
fi

cat >"/tmp/$VK_FILE_NAME" <<EOF
  # UPDATE SOURCE
  echo "Updating source from Git"
  cd $VK_BOT_PATH
  git pull

  # UPDATE GEMSET
  echo "Updating bundle"
  cd $VK_BOTSERVER_PATH
  $VK_RVM_WRAPPER/bundle install --without test
  $VK_RVM_WRAPPER/bundle update

  # UPDATE DATABASE
  cd $VK_BOTSERVER_PATH/app
  $VK_RVM_WRAPPER/rake vk:db:migrate

  # RESTART BOTSERVER
  echo "Restarting server"
  sudo service $VK_SERVICE_NAME restart
EOF

# Remove old version of upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER "[ -f $VK_FILE_NAME ] && rm $VK_FILE_NAME"

# Copy upgrade script to server
scp "/tmp/$VK_FILE_NAME" $DEPLOY_USER@$DEPLOY_SERVER:$VK_FILE_NAME

# Execute upgrade script
ssh $DEPLOY_USER@$DEPLOY_SERVER /bin/bash "./$VK_FILE_NAME"
DEPLOY_STATUS=$?

# Remove upgrade script from server
ssh $DEPLOY_USER@$DEPLOY_SERVER "[ -f $VK_FILE_NAME ] && rm $VK_FILE_NAME"

exit $DEPLOY_STATUS