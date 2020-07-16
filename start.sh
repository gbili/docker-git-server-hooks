#!/bin/sh

printenv;

# If there is some public key in keys folder
# then it copies its contents to authorized_keys file
if [ "$(ls -A ${GIT_SSH_PUBKEYS_DIR}/)" ]; then
  cat ${GIT_SSH_PUBKEYS_DIR}/*.pub > ${GIT_HOME}/.ssh/authorized_keys
  chown -R git:git ${GIT_HOME}/.ssh
  chmod 700 ${GIT_HOME}/.ssh
  chmod -R 600 ${GIT_HOME}/.ssh/*
fi

# Checking permissions and fixing SGID bit in repos folder
# More info: https://github.com/jkarlosb/git-server-docker/issues/1
# User specific repos dir
if [ -d "${GIT_REPOS_DIR}" ]; then
  echo "Setting up ${GIT_REPOS_DIR}";
  chown -R git:${COMMON_GROUP} ${GIT_REPOS_DIR}
  chmod -R ug+rwX ${GIT_REPOS_DIR}
  # Ensure all future content in the folder will inherit group ownership
  find ${GIT_REPOS_DIR} -type d -exec chmod g+s '{}' +
fi

# node UID will likely change from container to container
# so we give full access to it's group
# IMPORTANT: if another container wants to write there,
# add a group with same GID
if [ -d "${GIT_REPOS_DEPLOY_ROOT_DIR}" ]; then
  echo "Setting up ${GIT_REPOS_DEPLOY_ROOT_DIR}";
  chown -R node:${COMMON_GROUP} ${GIT_REPOS_DEPLOY_ROOT_DIR}
  chmod -R 2770 ${GIT_REPOS_DEPLOY_ROOT_DIR}
  chmod g+s ${GIT_REPOS_DEPLOY_ROOT_DIR}
  # Let bilder know the GID of the common group
  # This will allow sharing volume permissions
  # with other containers
  echo "Will print group:password:GID:user(s) of deploy dir:"
  getent group ${COMMON_GROUP}
  ls -la ${GIT_REPOS_DEPLOY_ROOT_DIR}
fi

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D