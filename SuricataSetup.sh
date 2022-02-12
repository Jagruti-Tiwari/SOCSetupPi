#SURICATA INSTALLATION STEPS

user=`whoami`



#Step I - Install the dependencies

 sudo apt-get install python3-pip -y
 echo "python install done"
 sudo apt-get install libnss3-dev -y
 echo "libnss3 install done"
 sudo apt-get install liblz4-dev -y
 echo "liblz4 install done"
 sudo apt-get install libnspr4-dev -y
 echo "libnspr4 install done"
 sudo apt-get install libcap-ng-dev -y
 echo "libcap-ng install done"
 sudo apt-get install git -y
 echo "git install done"

 #Step II - Installation of Suricata

 sudo apt install libpcre3 libpcre3-dbg libpcre3-dev build-essential libpcap-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev make libmagic-dev libjansson-dev rustc cargo python-yaml python3-yaml liblua5.1-dev
 echo "------------------------------------"
 wget https://www.openinfosecfoundation.org/download/suricata-6.0.4.tar.gz
 echo "------------------------------------"
 tar -xvf suricata-6.0.4.tar.gz
 echo "------------------------------------"
 cd suricata-6.0.4/
 ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-nfqueue --enable-lua
 make
 sudo make install
 echo "------------------------------------"
 cd suricata-update/
 sudo python3 setup.py build
 sudo python3 setup.py install
 cd ..
 sudo make install-full
 echo "------------------------------------"
 #Step III - Setup suricata as service

 touch “/etc/systemd/system/suricata.service”
 
 wget https://raw.githubusercontent.com/Jagruti-Tiwari/SOCSetupPi/main/suricata.service
 cp suricata.service /etc/systemd/system/suricata.service
 sudo systemctl enable suricata.service

# Step IV - Update Suricata
sudo suricata-update
sudo suricata-update update-sources
sudo suricata-update check-versions
