#!/bin/sh

printenv;

# alias to match git-server-hooks naming conventions
# user
if [ -z "${GIT_REPOS_OWNERNAME}" ]; then
  GIT_REPOS_OWNERNAME=user
fi

# /u/user
if [ -z "${GIT_REPOS_DIR}" ]; then
  GIT_REPOS_DIR=${GIT_SERVER_DIR}/${GIT_REPOS_OWNERNAME}
fi

# /node-server/user
if [ -z "${GIT_REPOS_DEPLOY_ROOT_DIR}" ]; then
  GIT_REPOS_DEPLOY_ROOT_DIR=${NODE_SERVER_DIR}/${GIT_REPOS_OWNERNAME}
fi

# Initialize the deployment dir for the repo
mkdir -p ${GIT_REPOS_DEPLOY_ROOT_DIR}

# Let bilder know the GID of the common group
# This will allow sharing volume permissions
# with other containers
RUN getent group ${COMMON_GROUP}

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
mkdir -p ${GIT_REPOS_DIR}
if [ -d "${GIT_REPOS_DIR}" ]; then
  echo "Dir ${GIT_REPOS_DIR}, exists, nice!";
else
  echo "Not able to create ${GIT_REPOS_DIR}";
  echo "Exiting";
  exit -1;
fi
echo "Setting up ${GIT_REPOS_DIR}";
chown -R git:${COMMON_GROUP} ${GIT_REPOS_DIR};
chmod -R ug+rwX ${GIT_REPOS_DIR};
# Ensure all future content in the folder will inherit group ownership
find ${GIT_REPOS_DIR} -type d -exec chmod g+s '{}' +


# node UID will likely change from container to container
# so we give full access to it's group
# IMPORTANT: if another container wants to write there,
# add a group with same GID
mkdir -p ${GIT_REPOS_DEPLOY_ROOT_DIR};
if [ -d "${GIT_REPOS_DEPLOY_ROOT_DIR}" ]; then
  echo "Dir ${GIT_REPOS_DEPLOY_ROOT_DIR}, exists, nice!";
else
  echo "Not able to create ${GIT_REPOS_DEPLOY_ROOT_DIR}";
  echo "Exiting";
  exit -1;
fi
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

# -D flag avoids executing sshd as a daemon
exec /usr/sbin/sshd -D