#!/bin/bash -l

echo "Setting git defaults"
git config --global user.email "bot@pushbit.co"
git config --global user.name "pushbot"
git config --global push.default simple

echo "cloning git repo"
git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git target

echo "entering git repo"
cd target

echo "checking out new branch"
git checkout ${BASE_BRANCH}

ruby ../execute.rb 
