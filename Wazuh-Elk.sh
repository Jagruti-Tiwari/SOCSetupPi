#Root user privileges are required to execute all the commands described below.
#Prerequisites Install all the necessary packages:


apt-get install apt-transport-https zip unzip lsb-release curl gnupg -y
echo "Installed necessary packages"

#Installing Elasticsearch - Adding the Elastic Stack repository

#1. Install the GPG key:

curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

#2. Add the repository:

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list

#3. Update the package information:

apt-get update

#Elasticsearch installation and configuration 1. Install the Elasticsearch package:

apt-get install elasticsearch=7.14.2

#2. Download the configuration file /etc/elasticsearch/elasticsearch.yml as follows:

curl -so /etc/elasticsearch/elasticsearch.yml https://packages.wazuh.com/resources/4.2/elastic-stack/elasticsearch/7.x/elasticsearch_all_in_one.yml

#Certificates creation and deployment
# 1. Download the configuration file for creating the certificates:
curl -so /usr/share/elasticsearch/instances.yml https://packages.wazuh.com/resources/4.2/elastic-stack/instances_aio.yml

#2. The certificates can be created using the elasticsearch-certutil tool:
/usr/share/elasticsearch/bin/elasticsearch-certutil cert ca --pem --in instances.yml --keep-ca-key --out ~/certs.zip

#3. Extract the generated /usr/share/elasticsearch/certs.zip file from the previous step.
unzip ~/certs.zip -d ~/certs

#4. The next step is to create the directory /etc/elasticsearch/certs, and then copy the CA file, the certificate and the key there:

mkdir /etc/elasticsearch/certs/ca -p
cp -R ~/certs/ca/ ~/certs/elasticsearch/* /etc/elasticsearch/certs/
chown -R elasticsearch: /etc/elasticsearch/certs
chmod -R 500 /etc/elasticsearch/certs
chmod 400 /etc/elasticsearch/certs/ca/ca.* /etc/elasticsearch/certs/elasticsearch.*
rm -rf ~/certs/ ~/certs.zip

#5. Enable and start the Elasticsearch service:

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch

#6. Generate credentials for all the Elastic Stack pre-built roles and users:
 #/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto >> pass.txt
#The command above will display password. Save the password of the elastic user for further steps

#To check that the installation was made successfully, run the following command replacing <elastic_password> by the password generated on the previous step for elastic user:
curl -XGET https://localhost:9200 -u elastic:<elastic_password> -k

#Installing Wazuh server
#Adding the Wazuh repository 1. Install the GPG key: 
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - 
#2. Add the repository: 
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
#3. Update the package information: 
apt-get update

#Installing the Wazuh manager 1. Install the Wazuh manager package: 
apt-get install wazuh-manager
#2. Enable and start the Wazuh manager service: 
systemctl daemon-reload 
systemctl enable wazuh-manager 
systemctl start wazuh-manager

#3. Run the following command to check if the Wazuh manager is active: 
systemctl status wazuh-manager

#Installing Filebeat Filebeat installation and configuration 1. Install the Filebeat package:
apt-get install filebeat=7.14.2

#2. Download the pre-configured Filebeat config file used to forward Wazuh alerts to Elasticsearch:
curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/resources/4.2/elastic-stack/filebeat/7.x/filebeat_all_in_one.yml

#3. Download the alerts template for Elasticsearch:
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/4.2/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json

#4. Download the Wazuh module for Filebeat: 
curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.1.tar.gz | tar -xvz -C /usr/share/filebeat/module

#5. Edit the file /etc/filebeat/filebeat.yml: output.elasticsearch.password: <elasticsearch_password>
#Replace elasticsearch_password with the previously generated password for elastic user.

#6. Copy the certificates into /etc/filebeat/certs/
cp -r /etc/elasticsearch/certs/ca/ /etc/filebeat/certs/ 
cp /etc/elasticsearch/certs/elasticsearch.crt /etc/filebeat/certs/filebeat.crt 
cp /etc/elasticsearch/certs/elasticsearch.key /etc/filebeat/certs/filebeat.key

#7. Enable and start the Filebeat service:
systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat

#To ensure that Filebeat has been successfully installed, run the following command:
filebeat test output

#Kibana installation and configuration 1. Install the Kibana package:
apt-get install kibana=7.14.2

#2. Copy the Elasticsearch certificates into the Kibana configuration folder:
mkdir /etc/kibana/certs/ca -p
cp -R /etc/elasticsearch/certs/ca/ /etc/kibana/certs/
cp /etc/elasticsearch/certs/elasticsearch.key /etc/kibana/certs/kibana.key
cp /etc/elasticsearch/certs/elasticsearch.crt /etc/kibana/certs/kibana.crt
chown -R kibana:kibana /etc/kibana/
chmod -R 500 /etc/kibana/certs
chmod 440 /etc/kibana/certs/ca/ca.* /etc/kibana/certs/kibana.*

#3. Download the Kibana configuration file:
curl -so /etc/kibana/kibana.yml https://packages.wazuh.com/resources/4.2/elastic-stack/kibana/7.x/kibana_all_in_one.yml

#Edit the /etc/kibana/kibana.yml file:
#elasticsearch.password: <elasticsearch_password>
#Values to be replaced: <elasticsearch_password>: the password generated during the Elasticsearch installation and configuration for the elastic user.

#4. Create the /usr/share/kibana/data directory:
mkdir /usr/share/kibana/data
chown -R kibana:kibana /usr/share/kibana

#5. Install the Wazuh Kibana plugin. The installation of the plugin must be done from the Kibana home directory as follows:
cd /usr/share/kibana
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-4.2.5_7.14.2-1.zip

#6. Link Kibana’s socket to privileged port 443:
setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node

#7. Enable and start the Kibana service:
systemctl daemon-reload
systemctl enable kibana
systemctl start kibana

#8. Access the web interface using the password generated during the Elasticsearch installation process:
#URL: https://<wazuh_server_ip>
#user: elastic
#password: <PASSWORD_elastic>

#Disabling repositories It is recommended to disable the repositories so that the individual packages will not be updated unintentionally which could potentially lead to having a version of the Elastic Stack for which the Wazuh integration has not been released yet.
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-7.x.list
apt-get update
