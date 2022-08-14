#!/usr/bin/env bash

echo -e 'export PATH="$HOME/.rbenv/bin:$PATH"\neval "$(rbenv init -)"' | tee ~/.bash_profile ~/.bashrc

if [ -d ~/.rbenv ];then exit;fi
echo "+ installing rbenv .."
git clone https://github.com/rbenv/rbenv.git ~/.rbenv

export PATH="$HOME/.rbenv/bin:$PATH
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# Add rbenv paths and eval to .bashrc and .bash_profile (needed in login/non-login shells)



. ~/.bash_profile

# eval "$(rbenv init -)
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 3.1.1
rbenv global 3.1.1

echo -e "install: --no-ri --no-rdoc\nupdate: --no-ri --no-rdoc" > ~/.gemrc