#! /bin/bash

# Openstack's Server creation script

# Enabling colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'


# Variables

hostfile="files/hosts"
ansiblehostfile="files/ansible_hosts"
slurmfile="files/slurm.conf"

flavor=6
image="7c721014-31fd-44da-bf69-360a6d945e52"
network="39b3d618-b5bf-4fc0-8e0d-fe1094698d3f"
keypair="l0kshSSH"
masterdata="files/user-data_master.txt"
nodedata="files/user-data_node.txt"

# Funtion Definition

clusterCreate(){
   
  echo -e "${YELLOW}Creating cluster ...${NC}"
# Creating master node
  openstack server create --flavor $flavor --image $image --nic net-id=$network \
  --key-name $keypair --user-data $masterdata master &> /dev/null
  sleep 3

# Creating worker nodes
  for ((i=1; i<=${1}; i++))  
  do
  sed -i "s/cn0./cn0${i}/g" $nodedata
  openstack server create --flavor $flavor --image $image --nic net-id=$network \
  --key-name $keypair --user-data $nodedata "cn0${i}" &> /dev/null
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
. scripts/hosts.sh
 
# Cluster access information
M_IP=`grep "master" $hostfile | cut -d " " -f1`
echo

echo -e "${GREEN}To access the cluster login to the master : ${NC}"
echo -e "${GREEN}master's ip : ${M_IP} ${NC}"


#####################################################################################
########################### Updating ansible hosts file #############################
#####################################################################################

masterip=`grep "master" files/hosts| cut -d " " -f1`

hostsUpdate(){

echo "[servers]" > $ansiblehostfile
echo "master ansible_ssh_host=${masterip}" >> $ansiblehostfile
for ((i=1; i<=$1; i++))
  do
  cnip=`grep "cn0${i}" files/hosts| cut -d " " -f1`
  echo "cn0${i} ansible_ssh_host=${cnip}" >> $ansiblehostfile
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

echo "y" | cp $ansiblehostfile /etc/ansible/hosts &> /dev/null
echo "y" | cp $hostfile /etc/hosts &> /dev/null

################################################
# Updating slurm.conf
################################################

sed -i "s/^ControlAddr=.*/ControlAddr=$masterip/g" $slurmfile
sed -i "s/^NodeName=.*/NodeName=cn[01-0${NCN}] CPUs=2 Boards=1 SocketsPerBoard=2 CoresPerSocket=1 ThreadsPerCore=1/g" $slurmfile
