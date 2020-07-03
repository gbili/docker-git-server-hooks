# Git Server Hooks

A docker layer intended to allow simple deployment of code using a git server and post-receive hooks.

## Adding the keys

When launching, `gbili/git-server-hooks` will execute `start.sh` script. The script uses the keys present in `/<GIT_SERVER_DIR>/keys/somekey.pub` and adds them to to the end of `/home/git/.ssh/authorized_keys`'s file.

> It tells `openssh`: who is allowed to login using RSA authentication

Since we want to push to the Git repo, we must make sure `start.sh` will find our public key in `/<GIT_SERVER_DIR>/keys` at container launch and copy it to `.ssh` for us.

> Adding them to the built image is a bad idea if your image is not private. So, how can we put the RSA keys to our container without adding them to the docker image ?

The solution is to use _named volumes_. We will create a volume named `git-server-keys` and mount it to our container at `/<GIT_SERVER_DIR>/keys`. But of course this does not solve our problem entirely, we still need to put the data in it before our `gbili/git-server-hooks` container starts.

We can do that using a temporary container that will solely serve as a volume "populator". We will remove the temporary container once it has fulfilled its duty of adding the keys to the volume `git-server-keys`.

**IMPORTANT**: `docker-compose` may name your volumes with a prefix, so `git-server-keys` volume in `docker-compose.yml` may end up renamed: `git-sever-hooks_git-server-keys`

Let's do it. Steps are:

1. Put your _local_ `id_rsa.pub` on the _host_ machine (i.e. where _local_ is the development machine intended to call git push, and _host_ is where your docker `gbili/git-server-hooks` container will run).

   ```sh
   sftp <host_username>@<host_hostname>
   # within the host, move to a place where you would like to temporarily store your local public keys
   > cd ~/.g-ssh
   > put /home/g/.ssh/id_rsa.pub # press enter, (alternatively you can drag the local file to get the path)
   > bye
   ```

2. Ssh to the host `ssh <host_user>@<host_hostname>` and populate the volume with the public keys file using a temporary container

   ```sh
   # move to the directory where you placed the public key
   cd ~/.g-ssh
   # create a container on which we mount git-server-hooks_git-server-keys at /data
   docker container create --name temp -v git-server-hooks_git-server-keys:/data busybox
   # copy contents of ./some_temp_dir... into temp's container /data dir
   docker cp . temp:/data
   # we can remove the container, and still keep the contents
   docker rm temp
   ```

3. We can now `docker-compose up`, and the container will be able to see the public keys files in `/<GIT_SERVER_DIR>/keys` directory since we are mounting `git-sever-hooks_git-server-keys` that will be mounted there.

   ```bash
   # move to where you have the docker-compose.yml file for the git-server-hooks
   cd some-dir/git-server-hooks
   ls # docker-compose.yml
   docker-compose up -d
   ```

4. Let's check whether the keys are really there

   ```bash
   docker exec -it git-server-hooks sh
   > more /home/git/.ssh/authorized_keys
   ```

Once these are added and you have set up and reverse nginx proxy for ssl, you can push with:

```bash
git remote add live ssh://git@<HOST_NAME>:2222/<GIT_SERVER_DIR>/<GIT_REPO_OWNERNAME>/<GIT_REPO_NAME>.git
git push live master
```

## Arguments (ARG) and defaults

- `GIT_HOME=/home/git`: `/home/git`
- `GIT_REPO_DEPLOY_DIR=${NODE_SERVER_DIR}/${GIT_REPO_OWNERNAME}/${GIT_REPO_NAME}`: `/node-server/user/repo`
- `GIT_REPO_DIR=${GIT_REPOS_DIR}/${GIT_REPO_NAME}.git`: `/u/user/repo.git`
- `GIT_REPO_NAME=repo`: `repo`
- `GIT_REPO_OWNERNAME=user`: `user`
- `GIT_REPOS_DIR=${GIT_SERVER_DIR}/${GIT_REPO_OWNERNAME}`: `/u/user`
- `GIT_SERVER_DIR=/u`: `/u`
- `GIT_SSH_PUBKEYS_DIR=${GIT_SERVER_DIR}/keys`: `/u/keys`
- `NODE_SERVER_DIR=/node-server`: `/node-server`

## Environment variables (ENV) and defaults

Env variables use defaults from build arguments.

- `GIT_HOME=${GIT_HOME}`: `/home/git`
- `GIT_SERVER_DIR=${GIT_SERVER_DIR}`: `/u`
- `GIT_REPO_NAME=${GIT_REPO_NAME}`: `repo`
- `GIT_REPOS_DIR=${GIT_REPOS_DIR}`: `/u/user`
- `GIT_REPO_DIR=${GIT_REPO_DIR}`: `/u/user/repo.git`
- `GIT_REPO_DEPLOY_DIR=${GIT_REPO_DEPLOY_DIR}`: `/node-server/user/repo`
- `GIT_SSH_PUBKEYS_DIR=${GIT_SSH_PUBKEYS_DIR}`: `/u/keys`

### Env variables in git hooks scripts

**ISSUE**: Git hooks does not pass the `git` user's environmental variables to hook scripts, (e.g. to `hooks/post-receive`).

If you need env variables in your scripts, you should `sed` them at build time. check `sed` instruction in `start.sh` as an example.

## Building your own image

For building there are a set of arguments you can use to change for example the repository dir, check Arguments section.

Example changing the repo dir from `/u/user/repo.git` to `/u/gbili/blog.git` you do:

```sh
sudo docker build \
--build-arg GIT_REPO_OWNERNAME=gbili \
--build-arg GIT_REPO_NAME=blog \
-t gbili/git-server-hooks:0.0.3
```

## Addig new repositories

There are different possible approaches for adding new repositories.

### Option 1: manually login

The easiest one to set up, yet maybe the least handy is to login to your container and create the repo manually (adapt `user` and `newrepo` to your situation):

1. Go to your host machine
2. Login to your container

   ```sh
   docker exec -it git-server-hooks sh
   ```

3. Change the user to `git` so we don't have issues later:

   ```sh
   su git
   ```

4. Change to git repos directory directory and initialize:

   ```sh
   cd /u/user
   mkdir newrepo.git
   cd newrepo.git
   git init --bare
   ```

5. exit and done, you can now use:

   ```sh
   git remote add live ssh://git@<VIRTUAL_HOST>:2222/u/user/newrepo.git
   git push live
   ```

### Option 2: using a separate container

Using a separate container, requires using a different port

### Option 3: using _new repo_ container

**TODO**: Using a _new repo_ container that would mount on the `git-server-repos` volume and perform the actions in option 1.

### Option 4: creating a special repo

**TODO**: Creating a special repo that has a pre push hook that would create a repo for us and output the remote

## Adding a new user

**TODO**: Adding a new user is not possible. For one, they would share access to `git` user, therefore they could run scripts on each others' land. Secondly, the `git-server-repos` volume is mounted relative to one user. We would need to mount it relative to the `git-server` root, and adapt scripts accordingly.

## Running the node server

Once your code has been copied to the `node-apps` volume, you still need to run it. Since it is a named volume, it should be easy for you to attach a different container that is capable of serving the node app from a filesystem. As well as monitoring changes to files in order to restart.

**NOTE**: the cool thing with having a separate container, is that we can run different integration steps.

**TODO**: look into docker inter-container communication.
