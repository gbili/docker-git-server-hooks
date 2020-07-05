#!/bin/sh
echo "post-receive hook is being executed in server"
while read oldrev newrev ref
do
    echo "oldrev: $oldrev, newrev: $newrev, ref: $ref"
    branch=$(git rev-parse --symbolic --abbrev-ref $ref)

    if [[ "$branch" = "master" || "$branch" = "dev" ]];
    then
        echo "$ref ref received.  Deploying $branch branch to production..."
        echo "Current env: "
        printenv;
        echo "Copying files to node deploy dir:"
        unset GIT_INDEX_FILE;
        git --work-tree=GIT_REPO_DEPLOY_DIR --git-dir=GIT_REPO_DIR checkout -f $branch;
        echo "Moving to node deploy dir:"
        cd GIT_REPO_DEPLOY_DIR;
        echo "Adding /usr/local/bin to PATH for npm node etc."
        export PATH="/usr/local/bin:${PATH}"
        echo "Will install node modules:"
        npm i;
        echo "See how permissions are, does group have rwx access to all files and dir ?"
        ls -la
        echo "Chmodding: "
        chmod -R ug+rwx .
        echo "Make sure permissions are ok for node group in other container:"
        ls -la
        echo "SUCCESS: Node server has been updated, make sure to restart it."
    else
        echo "Ref $ref successfully received.  Doing nothing: only the dev and m
aster branch may be deployed on this server."
    fi
done