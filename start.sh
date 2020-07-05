#!/bin/sh

printenv;

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
  # Ensure all future content in the folder will inherit group ownership
  find . -type d -exec chmod g+s '{}' +
fi

# node UID will likely change from container to container
# so we give full access to it's group
# IMPORTANT: if another container wants to write there,
# add a group with same GID
if [ "$(ls -A ${GIT_REPO_DEPLOY_DIR}/)" ]; then
  cd ${GIT_REPO_DEPLOY_DIR}
  chown -R node:${COMMON_GROUP} .
  chmod -R ug+rwX .
  find . -type d -exec chmod g+s '{}' +
  # Let bilder know the GID of the common group
  # This will allow sharing volume permissions
  # with other containers
  echo "Will print group:password:GID:user(s) of deploy dir:"
  echo getent group ${COMMON_GROUP}
  ls -la ${GIT_REPO_DEPLOY_DIR}
  echo "Be careful with the above output, it is likely that the actual sub repo dir has different owner and group"
fi

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D