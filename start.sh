#!/bin/sh

# If there is some public key in keys folder
# then it copies its contents to authorized_keys file
if [ "$(ls -A ${GIT_SSH_PUBKEYS_DIR}/)" ]; then
  cd $GIT_HOME
  cat $GIT_SSH_PUBKEYS_DIR/*.pub > .ssh/authorized_keys
  chown -R git:git .ssh
  chmod 700 .ssh
  chmod -R 600 .ssh/*
fi

# Replace environment variables in git hooks
# They get not passed to the hook so we need to hardcode them
if [ -f "${GIT_REPO_DIR}/hooks/post-receive" ]; then
  echo "Sedding into ${GIT_REPO_DIR}/hooks/post-receive"
  sed -i -e "s#GIT_REPO_DEPLOY_DIR#$GIT_REPO_DEPLOY_DIR#g" "${GIT_REPO_DIR}/hooks/post-receive"
  sed -i -e "s#GIT_REPO_DIR#${GIT_REPO_DIR}#g" "${GIT_REPO_DIR}/hooks/post-receive"
fi

# Checking permissions and fixing SGID bit in repos folder
# More info: https://github.com/jkarlosb/git-server-docker/issues/1
if [ "$(ls -A ${GIT_REPOS_DIR}/)" ]; then
  cd $GIT_REPOS_DIR
  chown -R git:${COMMON_GROUP} .
  chmod -R ug+rwX .
  find . -type d -exec chmod g+s '{}' +
fi

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D