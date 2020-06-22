# Git Server Hooks

A docker layer intended to allow simple deployement of code using a git server and post-receive hooks.

In order to allow ssh authentication to git, you need to add the pusher's public key with:

```dockerfile
# 3. Add some authorized keys or pass them as an envvar?
# create a tmp dir to copy the keys
ARG LUSER
ADD /home/$LUSER/.ssh/id_rsa.pub /tmp/id_rsa.$LUSER.pub
RUN cat /tmp/id_rsa.$LUSER.pub >> ~/.ssh/authorized_keys

# OR

# 3. Alternatively pass them as an arg
ARG SSHKEYPUB
RUN cat $SSHKEYPUB >> ~/.ssh/authorized_keys
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
