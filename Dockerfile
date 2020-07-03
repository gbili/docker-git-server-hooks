FROM node:erbium-alpine
# https://github.com/timbru31/docker-node-alpine-git
LABEL maintainer "Guillermo Pages <docker@guillermo.at>"

# Allow cache invalidation 
ARG REFRESHED_AT
ENV REFRESHED_AT $REFRESHED_AT

# /home/git
ARG GIT_HOME=/home/git

# /u
ARG GIT_SERVER_DIR=/u

# /node-server
ARG NODE_SERVER_DIR=/node-server

# user
ARG GIT_REPO_OWNERNAME=user

# repo
ARG GIT_REPO_NAME=repo

# /u/user
ARG GIT_REPOS_DIR=${GIT_SERVER_DIR}/${GIT_REPO_OWNERNAME}

# /u/user/repo.git
ARG GIT_REPO_DIR=${GIT_REPOS_DIR}/${GIT_REPO_NAME}.git

# /node-server/user/repo
ARG GIT_REPO_DEPLOY_DIR=${NODE_SERVER_DIR}/${GIT_REPO_OWNERNAME}/${GIT_REPO_NAME}

# /u/keys
ARG GIT_SSH_PUBKEYS_DIR=${GIT_SERVER_DIR}/keys

ENV GIT_HOME=${GIT_HOME}
ENV GIT_SERVER_DIR=${GIT_SERVER_DIR}
ENV GIT_REPO_NAME=${GIT_REPO_NAME}
ENV GIT_REPOS_DIR=${GIT_REPOS_DIR}
ENV GIT_REPO_DIR=${GIT_REPO_DIR}
ENV GIT_REPO_DEPLOY_DIR=${GIT_REPO_DEPLOY_DIR}
ENV GIT_SSH_PUBKEYS_DIR=${GIT_SSH_PUBKEYS_DIR}

# "--no-cache" is new in Alpine 3.3 and it avoid using
# "--update + rm -rf /var/cache/apk/*" (to remove cache)
RUN apk add --no-cache \
# openssh=7.2_p2-r1 \
  openssh \
# git=2.8.3-r0
  git

# Key generation on the server
RUN ssh-keygen -A

# Create the server base dir
WORKDIR ${GIT_SERVER_DIR}

# -s flag changes user's shell
# Eg: -s /usr/bin/git-shell
RUN mkdir ${GIT_SSH_PUBKEYS_DIR} \
  && adduser --disabled-password git \
  && echo git:12345 | chpasswd \
  && mkdir ${GIT_HOME}/.ssh

# sshd_config file is edited to enable key access and disable password access
COPY sshd_config /etc/ssh/sshd_config

# Add start script to image, should be called by extenders
COPY start.sh start.sh
RUN chmod +x start.sh

# IMPORTANT: Remember to add your public keys to the git-server-keys volume using a temporary container before starting this one

# Define arguments (usage: --build-arg LUSER=g)
# ARG GIT_REPO_NAME=repo

ARG COMMON_GROUP=nodegit

# 6. Initialize the repo
WORKDIR ${GIT_REPO_DIR}
RUN git init --bare

# 7. Add a post-receive hook
# You can use ENV variables within them but make sure
# to remove the $ and use sed to replace them with the value (see start.sh)
COPY hooks/post-receive.tpl ${GIT_REPO_DIR}/hooks/post-receive
RUN chmod -R 770 ${GIT_REPO_DIR}/hooks/post-receive

# We need a common group for node and git
# to allow each of them writing contents to deploy dir
RUN addgroup ${COMMON_GROUP}
RUN addgroup git ${COMMON_GROUP}
RUN addgroup node ${COMMON_GROUP}

# Initialize the deployment dir for the repo
# a. to write in the deploy dir
WORKDIR ${GIT_REPO_DEPLOY_DIR}
RUN chown -R node:${COMMON_GROUP} .
RUN chmod -R 770 .

EXPOSE 22

# 8. Start the server using nsg start.sh script
ENTRYPOINT ["sh", "-c", "${GIT_SERVER_DIR}/start.sh"]