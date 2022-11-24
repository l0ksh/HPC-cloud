#! /bin/bash

# This script will delete the existing cluster.

# Openstack's Server creation script

# Enabling colors

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clusterDelete(){
  echo -e "${YELLOW}Deleting cluster ...${NC}"
  sleep 1

  nodeNames=`openstack server list | awk -F'[|]' '{print $3}' | grep cn | sed 's/^ *//g' | tr '\n' ' '`

  openstack server delete master $nodeNames &> /dev/null
  policystatus=$?
  if [[ $policystatus -eq 0 ]]
  then
    echo -e "${GREEN}Cluster deleted${NC}"
  else
    echo -e "${RED}Cluster is not present or already deleted${NC}"
  fi
}
clusterDelete
