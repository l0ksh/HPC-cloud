#! /bin/bash

# Openstack's Server creation script

# Enabling colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'


# Variables

flavor=6
image="CentOS with SLURM"
network="39b3d618-b5bf-4fc0-8e0d-fe1094698d3f"
keypair="l0kshSSH"
masterdata="~/slurm_playbook/files/user-data1.txt master"
nodedata="~/slurm_playbook/files/user-data.txt"

# Funtion Definition

clusterCreate(){
   
  echo -e "${YELLOW}Creating cluster ...${NC}"
# Creating master node
  openstack server create --flavor 6 --image "CentOS with SLURM" --nic net-id=39b3d618-b5bf-4fc0-8e0d-fe1094698d3f --key-name l0kshSSH --user-data ~/slurm_playbook/files/user-data1.txt master &> /dev/null
  sleep 3

# Creating worker nodes
  for ((i=1; i<=${1}; i++))  
  do
  sed -i "s/cn0./cn0${i}/g" ~/slurm_playbook/files/user-data.txt
  openstack server create --flavor 6 --image "CentOS with SLURM" --nic net-id=39b3d618-b5bf-4fc0-8e0d-fe1094698d3f --key-name l0kshSSH --user-data ~/slurm_playbook/files/user-data.txt "cn0${i}" &> /dev/null
  done
  echo -e "${GREEN}Cluster created${NC}"
}


####### Define variables #########

#Asking user the number of compute nodes

echo -n "Enter number of compute nodes: "
read NCN
sleep 1

#echo -e "Number of compute nodes to be created: $NCN"

echo -e "${RED}********** Cluster Information: **********${NC}"
echo -e "${BLUE}Master nodes: 1 ${NC}"
echo -e "${BLUE}Compute nodes: ${NCN} ${NC}"
echo

clusterCreate ${NCN}
sleep 5

# Creating hosts file
. ~/slurm_playbook/scripts/hosts.sh
 
# Cluster access information
M_IP=`grep "master" ~/slurm_playbook/files/hosts| cut -d " " -f1`
echo

echo -e "${GREEN}To access the cluster login to the master : ${NC}"
echo -e "${GREEN}master's ip : ${M_IP} ${NC}"


#####################################################################################
########################### Updating ansible hosts file #############################
#####################################################################################

echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > ~/slurm_playbook/files/hosts
openstack server list | awk -F'[|]' '{print $3 $5}' | grep 'cn\|master' | sed -e 's/public=//g' | sed 's/^ *//g' | awk ' { t = $1; $1 = $2; $2 = t; print; } '  >> ~/slurm_playbook/files/hosts

masterip=`grep "master" files/hosts| cut -d " " -f1`

hostsUpdate(){

echo "[servers]" > ~/slurm_playbook/files/ansible_hosts
#masterip=`grep "master" files/hosts| cut -d " " -f1`

echo "master ansible_ssh_host=${masterip}" >> ~/slurm_playbook/files/ansible_hosts

for ((i=1; i<=$1; i++))
  do
  cnip=`grep "cn0${i}" files/hosts| cut -d " " -f1`
  echo "cn0${i} ansible_ssh_host=${cnip}" >> ~/slurm_playbook/files/ansible_hosts
  done
}

sleep 3
hostsUpdate $NCN
policystatus=$?
if [[ policystatus -eq 0 ]]
then
  echo
  echo -e "${GREEN}Hosts file is updated${NC}"
else
  echo -e "${RED}Failed updating hosts file${NC}"
fi

cp ~/slurm_playbook/files/ansible_hosts /etc/ansible/hosts
cp ~/slurm_playbook/files/hosts /etc/hosts

################################################
# Updating slurm.conf
################################################

sed -i "s/^ControlAddr=.*/ControlAddr=$masterip/g" ~/slurm_playbook/files/slurm.conf
sed -i "s/^NodeName=.*/NodeName=cn[01-0${NCN}] CPUs=2 Boards=1 SocketsPerBoard=2 CoresPerSocket=1 ThreadsPerCore=1/g" ~/slurm_playbook/files/slurm.conf
