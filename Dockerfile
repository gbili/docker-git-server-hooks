# Allow customization of base image
FROM docker.zivili.ch/gbili/nsg AS nsg

# Define arguments (usage: --build-arg LUSER=g)
ARG GIT_REPO_NAME=repo

# Add these to env in order to use them in git's hooks/post-receive script
ENV GIT_REPO_DIR ${/git-server/repos/${GIT_REPO_NAME}:-/git-server/repos/repo}
# post-receive hook will copy and build the app ever time
# This should be a volume that will also be served
# by a different container
ENV GIT_REPO_SERVER_DIR /git-server/node-app

# Uncomment one of both options or do this in the extending Dockerfile
# ARG LUSER
# ARG SSHKEYPUB
# 3. Add some authorized keys or pass them as an envvar?
# create a tmp dir to copy the keys
# ADD /home/$LUSER/.ssh/id_rsa.pub /tmp/id_rsa.$LUSER.pub
# RUN cat /tmp/id_rsa.$LUSER.pub >> ~/.ssh/authorized_keys 

# 3. Alternatively pass them as an arg
# RUN cat $SSHKEYPUB >> ~/.ssh/authorized_keys 

# 6. Initialize the repo
WORKDIR ${GIT_REPO_DIR}
RUN git init --bare
# 7. Add a post-receive hook
COPY hooks/post-receive ${GIT_REPO_DIR}/hooks/post-receive
RUN chmod -R ug+x ${GIT_REPO_DIR}/hooks/post-receive

# 8. Start the server
# Do this on the extending Dockerfile
ENTRYPOINT [ "sh", "start.sh" ]