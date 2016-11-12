#!/bin/bash
# Full install Script for snort.
# Written by Sean Cruikshank.
# Make sure to check variables before running (ip, interface etc).

# Pause function.
pause(){
  local dummy
  read -s -r -p 'Press any key to continue or Ctrl+C to exit...' -n 1 dummy
}

# Get prerequisites and create snort root.
sudo apt-get install build-essential -y &&
sudo apt-get install libpcap-dev libpcre3-dev libdumbnet-dev -y &&
mkdir ~/snort_src &&
cd ~/snort_src &&

# Download and install Snort.
sudo apt-get install bison flex -y &&
sudo wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz &&
sudo tar -zxvf daq-2.0.6.tar.gz &&
(cd daq-2.0.6 && sudo ./configure && make && sudo make install &&
sudo apt-get install zlib1g-dev liblzma-dev openssl libssl-dev -y)&&
sudo wget https://www.snort.org/downloads/snort/snort-2.9.8.3.tar.gz &&
sudo tar -zxvf snort-2.9.8.3.tar.gz &&
(cd snort-2.9.8.3 && sudo ./configure --enable-sourcefire && make && sudo make install) &&
sudo ldconfig &&
sudo ln -s /usr/local/bin/snort /usr/sbin/snort &&
snort -V &&
pause &&

# Create normal user and group to run snort daemon.
sudo groupadd snort &&
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort &&

# Create neccessary files and folders.
sudo mkdir -p /etc/snort/rules/iplists &&
sudo mkdir /etc/snort/preproc_rules &&
sudo mkdir /usr/local/lib/snort_dynamicrules &&
sudo mkdir /etc/snort/so_rules &&
sudo mkdir -p /var/log/snort/archived_logs &&
sudo touch /etc/snort/rules/iplists/black_list.rules &&
sudo touch /etc/snort/rules/iplists/white_list.rules &&
sudo touch /etc/snort/rules/local.rules &&
sudo touch /etc/snort/sid-msg.map &&

# Set permissions on files and folders.
sudo chmod -R 5775 /etc/snort &&
sudo chmod -R 5775 /var/log/snort &&
sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules &&
sudo chown -R snort:snort /etc/snort &&
sudo chown -R snort:snort /var/log/snort &&
sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules &&

# Copy config files and dynamic preprocessors and display snort structure.
(cd ~/snort_src/snort-2.9.8.3/etc/ && sudo cp *.conf* /etc/snort && sudo cp *.map /etc/snort && sudo cp *.dtd /etc/snort) &&
(cd ~/snort_src/snort-2.9.8.3/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/ && sudo cp * /usr/local/lib/snort_dynamicpreprocessor/) &&
sudo apt install tree &&
sudo tree /etc/snort/ &&
pause &&

# Add correct rulepaths to snort.conf
sudo sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf &&
sudo sed -i "45s|ipvar HOME_NET any|ipvar HOME_NET X.X.X.X|" /etc/snort/snort.conf &&
sudo sed -i "104s|var RULE_PATH ../rules|var RULE_PATH /etc/snort/rules|" /etc/snort/snort.conf &&
sudo sed -i "105s|var SO_RULE_PATH ../so_rules|var SO_RULE_PATH /etc/snort/so_rules|" /etc/snort/snort.conf &&
sudo sed -i "106s|var PREPROC_RULE_PATH ../preproc_rules|var PREPROC_RULE_PATH /etc/snort/preproc_rules|" /etc/snort/snort.conf &&
sudo sed -i "113s|var WHITE_LIST_PATH ../rules|var WHITE_LIST_PATH /etc/snort/rules/iplists|" /etc/snort/snort.conf &&
sudo sed -i "114s|var BLACK_LIST_PATH ../rules|var BLACK_LIST_PATH /etc/snort/rules/iplists|" /etc/snort/snort.conf &&

# Test if cofiguration is valid.
sudo snort -T -i <interface> -c /etc/snort/snort.conf &&
pause &&

# Setup test environment for snort.
echo "alert icmp any any -> $HOME_NET any (msg:"ICMP test detected"; GID:1; sid:10000001; rev:001; classtype:icmp-event;)" >> /etc/snort/rules/local.rules &&
echo "1 || 10000001 || 001 || icmp-event || 0 || ICMP Test detected || url,tools.ietf.org/html/rfc792" >> /etc/snort/sid-msg.map &&
sudo snort -T -c /etc/snort/snort.conf -i <interface> &&
pause &&

# Install prerequisites.
sudo apt-get install -y libcrypt-ssleay-perl liblwp-useragent-determined-perl &&

# Download and test PulledPork.
wget https://github.com/finchy/pulledpork/archive/patch-3.zip &&
sudo apt-get install zip unzip &&
unzip patch-3.zip &&
(cd pulledpork-patch-3 && sudo cp pulledpork.pl /usr/local/bin && sudo chmod +x /usr/local/bin/pulledpork.pl && sudo cp etc/*.conf /etc/snort/) &&
sudo /usr/local/bin/pulledpork.pl -V &&
pause &&

# PulledPork configuration.
sudo sed -i "19s%rule_url=https://www.snort.org/reg-rules/|snortrules-snapshot.tar.gz|<oinkcode>%rule_url=https://www.snort.org/reg-rules/|snortrules-snapshot.tar.gz|<your oinkcode>%" /etc/snort/pulledpork.conf &&
sudo sed -i "26s%rule_url=https://www.snort.org/reg-rules/|opensource.gz|<oinkcode>%rule_url=https://www.snort.org/reg-rules/|opensource.gz|<your oinkcode>%" /etc/snort/pulledpork.conf &&
sudo sed -i "29s%#rule_url=https://rules.emergingthreats.net/|emerging.rules.tar.gz|open-nogpl%rule_url=https://rules.emergingthreats.net/|emerging.rules.tar.gz|open-nogpl%" /etc/snort/pulledpork.conf &&
sudo sed -i "74s%rule_path=/usr/local/etc/snort/rules/snort.rules%rule_path=/etc/snort/rules/snort.rules%" /etc/snort/pulledpork.conf &&
sudo sed -i "89s%local_rules=/usr/local/etc/snort/rules/local.rules%local_rules=/etc/snort/rules/local.rules%" /etc/snort/pulledpork.conf &&
sudo sed -i "92s%sid_msg=/usr/local/etc/snort/sid-msg.map%sid_msg=/etc/snort/sid-msg.map%" /etc/snort/pulledpork.conf &&
sudo sed -i "96s%sid_msg_version=1%sid_msg_version=2%" /etc/snort/pulledpork.conf &&
sudo sed -i "119s%config_path=/usr/local/etc/snort/snort.conf%config_path=/etc/snort/snort.conf%" /etc/snort/pulledpork.conf &&
sudo sed -i "133s%distro=FreeBSD-8.1%distro=Ubuntu-12-04%" /etc/snort/pulledpork.conf &&
sudo sed -i "141s%black_list=/usr/local/etc/snort/rules/iplists/default.blacklist%black_list=/etc/snort/rules/iplists/black_list.rules%" /etc/snort/pulledpork.conf &&
sudo sed -i "150s%IPRVersion=/usr/local/etc/snort/rules/iplists%IPRVersion=/etc/snort/rules/iplists%" /etc/snort/pulledpork.conf &&

# Test PulledPork configuration.
sudo /usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l &&
pause &&

# Create Crontab for pulledpork updates.
crontab -l > pulledporkcron &&
echo "30 02 * * * /usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l" >> pulledporkcron &&
crontab pulledporkcron &&
crontab -l &&
pause &&

# Snort startup script.
echo "[Unit]" >> /lib/systemd/system/snort.service &&
echo "Description=Snort NIDS Daemon" >> /lib/systemd/system/snort.service &&
echo "After=syslog.target network.target" >> /lib/systemd/system/snort.service &&
echo "[Service]" >> /lib/systemd/system/snort.service &&
echo "Type=simple" >> /lib/systemd/system/snort.service &&
echo "ExecStart=/usr/local/bin/snort -q -u snort -g snort -c /etc/snort/snort.conf -i <interface>" >> /lib/systemd/system/snort.service &&
echo "[Install]" >> /lib/systemd/system/snort.service &&
echo "WantedBy=multi-user.target" >> /lib/systemd/system/snort.service &&
sudo systemctl enable snort &&
sudo systemctl start snort &&
sudo systemctl status snort &&
echo "Installation Complete"
