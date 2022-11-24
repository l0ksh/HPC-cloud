#! /bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

#Variables
hostfile="files/hosts"
slurmconf="files/slurm.conf"

#################### Fetching master, cn01 and cn02 ips ########################

echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > $hostfile
openstack server list | awk -F'[|]' '{print  $3 $5}'| head -c -1 | tail -n -3 | sed -e 's/public=//g' | sed 's/^ *//g' | awk ' { t = $1; $1 = $2; $2 = t; print; } ' >> $hostfile

#####################  Changing master, cn01 and cn02 ips ######################

masterip=`grep "master" $hostfile | cut -d " " -f1`
cn01ip=`grep "cn01" $hostfile | cut -d " " -f1`
cn02ip=`grep "cn02" $hostfile | cut -d " " -f1`

sed -i "s/^master ansible_ssh_host=.*/master\ ansible_ssh_host=$masterip/g" /etc/ansible/hosts
sed -i "s/^cn01 ansible_ssh_host=.*/cn01\ ansible_ssh_host=$cn01ip/g" /etc/ansible/hosts
sed -i "s/^cn02 ansible_ssh_host=.*/cn02\ ansible_ssh_host=$cn02ip/g" /etc/ansible/hosts

#################### Changing slurm controller ip ######################

slurmip=`grep "master" $hostfile | cut -d " " -f1`
sed -i "s/^ControlAddr=.*/ControlAddr=$masterip/g" $slurmconf

echo -e "${GREEN}Host ips were updated${NC}"
