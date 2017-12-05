#!/bin/bash

# For creating SSH keys between servers.

hostnames=`cat hostnames | grep -v "#"`

#### Copy Marvin and Archive keys into authorized_keys #####
cat keys >> authorized_keys


###### Create ssh keys on hosts specified in hostnames file######
###### Copy pub files back to this server #####
###### Cat pub files into authorized_keys #####

for host in ${hostnames}
do
  ssh -q $host "echo -e "\n\n\n" | ssh-keygen -t rsa -f .ssh/id_rsa"
  scp $host:/root/.ssh/id_rsa.pub $host
  cat $host >> authorized_keys
done



##### Copy authorized_keys back out to hosts specified in hostnames ######

for host in ${hostnames}
do
  scp authorized_keys $host:/root/.ssh/authorized_keys
done


rm -Rf authorized_keys

##### Clean up some file created during run time of this script ######
for host in ${hostnames}
do
  rm -Rf $host
done