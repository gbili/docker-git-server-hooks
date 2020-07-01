# Git Server Hooks

A docker layer intended to allow simple deployment of code using a git server and post-receive hooks.

## Adding the keys

When launching `gbili/git-server-hooks` will execute `gbili/nsg`'s `start.sh` script. The script uses the keys present in `/git-server/keys/somekey.pub` and adds them to to the end of `/home/git/.ssh/authorized_keys`'s file.

> This basically tells `openssh` who is allowed to login using RSA authentication

Since we want to push to the Git repo, we must make sure `start.sh` will find our public key in `/git-server/keys` at container launch and copy it to `.ssh` for us.

> How can we put the keys there other than directly adding them while building the image?

The solution is to use named volumes. We will create a volume named `git-server-keys` and mount it to our container at `/git-server/keys`. But of course this does not solve our problem, creating a volume is one thing, and putting data into it before our container starts is another.

The additional step that will make everything work, is to create the volume using a temporary container that will solely serve as a volume populator. Once the container has fulfilled its duty of adding the keys to the volume `git-server-keys`, we will discard the temp container.

Let's do it. Steps are:

1. Put your local `id_rsa.pub` to the host machine (i.e. where _local_ is the development machine that will later need to call git push, and _host_ is where your docker container based on `gbili/git-server-hooks` will run).

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

3. We can now compose up, and the container will be able to see the public keys files in `/git-server/keys` directory since it's our volume `git-sever-hooks_git-server-keys` that will be mounted there.

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

Once these are added you can easily push with:

```bash
git remote add production git@<IP_ADDRESS>:~/repo.git
git push production master
```

If you have set up and reverse nginx proxy for ssl with:

```bash
...?
```

you could do

```bash
git remote add production git@<server_name>:~/repo.git
git push production master
```
