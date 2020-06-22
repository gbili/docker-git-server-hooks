# Allow customization of base image
ARG BASE_IMAGE=gbili/node-ssh-git

FROM ${BASE_IMAGE}

# Define arguments (usage: --build-arg LUSER=g)
ARG GIT_REPO_DIR=~/repo.git
ARG SERVER_APP_DIR

# Add these args to env in order to use them in git's hooks/post-receive script
ENV GIT_REPO_DIR ${GIT_REPO_DIR:-~/repo.git}
ENV GIT_REPO_SERVER_DIR ${SERVER_APP_DIR:-/var/www/repo}

# 1. Create a git user account
RUN sudo adduser git
RUN su git
# 2. create .ssh directory for that user
RUN cd
RUN mkdir .ssh && chmod 700 .ssh
RUN touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys

# Uncomment one of both options or do this in the extending Dockerfile
# ARG LUSER
# ARG SSHKEYPUB
# 3. Add some authorized keys or pass them as an envvar?
# create a tmp dir to copy the keys
# ADD /home/$LUSER/.ssh/id_rsa.pub /tmp/id_rsa.$LUSER.pub
# RUN cat /tmp/id_rsa.$LUSER.pub >> ~/.ssh/authorized_keys 

# 3. Alternatively pass them as an arg
# RUN cat $SSHKEYPUB >> ~/.ssh/authorized_keys 

# 4. Create the git repositories dir
# 5. Create the git repo in the root dir
RUN mkdir -p ${GIT_REPO_DIR}
# 6. Initialize the repo
WORKDIR ${GIT_REPO_DIR}
RUN git init --bare
# 7. Add a post-receive hook
COPY hooks/post-receive ./hooks/post-receive

# Expose ssh port
EXPOSE 22