# Basic watobo installer
# Notes: missings "xterm" package. Requieres sudo (for packages and installing fxscintilla)

## Check if core packages are installed
if [ $(dpkg-query -W -f='${Status}' rvm 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo -e "\e[1;31m* RVM not installed. Installing...\e[0m"
  sudo apt-get update
  sudo apt install curl
  echo -e "\e[1;31m* NOTE: adding PGP keys \e[0m"
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer
  curl -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer.asc
  gpg --verify rvm-installer.asc && bash rvm-installer stable
  sudo usermod -a -G rvm $(whoami)
  echo -e "\e[1;31m* RVM Installed!\e[0m"
fi


source "$HOME/.rvm/scripts/rvm"

# Inject RVM into environment
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> .bashrc

echo -e "\e[1;31m* Installing Ruby v2.3.3...\e[0m"

rvm install 2.3.3


echo -e "\e[1;31m* Installing packages...\e[0m"
for pkg in git bzip2 build-essential openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev libgdbm-dev ncurses-dev automake libtool bison subversion pkg-config libffi-dev libx11-dev libxcursor-dev libxext-dev libxrandr-dev libxft2-dev freeglut3-dev libjpeg-turbo8-dev libjpeg8-dev libjpeg-dev zlib1g-dev libbz2-dev libpng12-dev libtiff5-dev libnfnetlink-dev libnetfilter-queue-dev libfox-1.6-dev xterm;
do
sudo apt-get -y install $pkg
done
 
echo "* installing fxscintilla ..."
wget http://download.savannah.gnu.org/releases/fxscintilla/fxscintilla-2.28.0.tar.gz
tar xzvf fxscintilla-2.28.0.tar.gz
cd fxscintilla-2.28.0
./configure --enable-shared
make
sudo make install
cd ..

echo -e "\e[1;31m* Switching ruby environment to 2.3.3...\e[0m"
rvm use ruby-2.3.3
echo -e "\e[1;31m* Installing some necessary gems...\e[0m"
gem install selenium-webdriver
gem install nfqueue
gem install bundler
gem install fxruby
 
echo -e "\e[1;31m* Now we get Watobo from git...\e[0m"
git clone https://github.com/siberas/watobo.git
cd watobo
bundle install
echo -e "\e[1;31m* Installation finished! Remember to run watobo from a login shell (bash --login).\e[0m"