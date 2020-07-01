# Allow customization of base image
FROM docker.zivili.ch/gbili/nsg

# IMPORTANT: Remember to add your public keys to the git-server-keys volume using a temporary container

# Define arguments (usage: --build-arg LUSER=g)
ARG GIT_REPO_NAME=repo

# Add these to env in order to use them in git's hooks/post-receive script
ENV GIT_REPO_DIR /git-server/repos/${GIT_REPO_NAME}
# post-receive hook will copy and build the app ever time
# This should be a volume that will also be served
# by a different container
ENV GIT_REPO_SERVER_DIR /git-server/node-app/${GIT_REPO_NAME}

RUN echo ${GIT_REPO_NAME} && \
  echo ${GIT_REPO_DIR} && \
  echo ${GIT_REPO_SERVER_DIR}

# 6. Initialize the repo
WORKDIR ${GIT_REPO_DIR}
RUN git init --bare

# 7. Add a post-receive hook
COPY hooks/post-receive ${GIT_REPO_DIR}/hooks/post-receive
RUN chmod -R ug+x ${GIT_REPO_DIR}/hooks/post-receive

# 8. Start the server using nsg start.sh script
ENTRYPOINT [ "sh", "/git-server/start.sh" ]