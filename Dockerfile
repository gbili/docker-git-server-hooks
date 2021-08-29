FROM node:erbium-alpine
# https://github.com/timbru31/docker-node-alpine-git
LABEL maintainer "Guillermo Pages <docker@guillermo.at>"

# Allow cache invalidation
ARG REFRESHED_AT
ENV REFRESHED_AT $REFRESHED_AT

# nodegit
ARG COMMON_GROUP=nodegit
ENV COMMON_GROUP=${COMMON_GROUP}

# /home/git
ARG GIT_HOME=/home/git
ENV GIT_HOME=${GIT_HOME}

# /u
ARG GIT_SERVER_DIR=/u
ENV GIT_SERVER_DIR=${GIT_SERVER_DIR}

# /node-server
ARG NODE_SERVER_DIR=/node-server
ENV NODE_SERVER_DIR=${NODE_SERVER_DIR}

# /u/keys
ARG GIT_SSH_PUBKEYS_DIR=${GIT_SERVER_DIR}/keys
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

# -s flag would change user's shell
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

# We need a common group for node and git
# to allow each of them writing contents to deploy dir
RUN addgroup ${COMMON_GROUP}
RUN addgroup git ${COMMON_GROUP}
RUN addgroup node ${COMMON_GROUP}

# Allow "git" user's group to write on its files
USER git
RUN umask 002
USER node
RUN umask 002

# Go back to root
USER root

EXPOSE 22

# 8. Start the server using nsg start.sh script
ENTRYPOINT ["sh", "-c", "${GIT_SERVER_DIR}/start.sh"]