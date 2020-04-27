#!/bin/bash

efs_mountpoint='fs-something.efs.ca-central-1.amazonaws.com'

chmod u+w ssh-key
terraform init
terraform apply --auto-approve
terraform output private_key > ssh-key
chmod 400 ssh-key

instance_ip=`terraform output instance_ip`


ssh -o "StrictHostKeyChecking=no" -l ec2-user -i ssh-key $instance_ip 'uname -a'
while test $? -gt 0
do
   sleep 5 # highly recommended - if it's in your local network, it can try an awful lot pretty quick...
   echo "Trying again..."
   ssh -o "StrictHostKeyChecking=no" -l ec2-user -i ssh-key $instance_ip 'uname -a'
done

#Deploy ffmpeg
ssh -l ec2-user -i ssh-key $instance_ip 'wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz'
ssh -l ec2-user -i ssh-key $instance_ip 'tar xvf ffmpeg-release-amd64-static.tar.xz'
ssh -l ec2-user -i ssh-key $instance_ip 'sudo mv ffmpeg-4.2.2-amd64-static /usr/local/bin/'
ssh -l ec2-user -i ssh-key $instance_ip 'sudo ln -s /usr/local/bin/ffmpeg-4.2.2-amd64-static/ffmpeg /usr/bin/ffmpeg'
ssh -l ec2-user -i ssh-key $instance_ip 'sudo ln -s /usr/local/bin/ffmpeg-4.2.2-amd64-static/ffprobe /usr/bin/ffprobe'

#Mount EFS where videos are stored
ssh -l ec2-user -i ssh-key $instance_ip 'mkdir videoconvert'
ssh -l ec2-user -i ssh-key $instance_ip "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $efs_mountpoint:/ videoconvert/"
ssh -l ec2-user -i ssh-key $instance_ip 'mkdir -p videoconvert/output videoconvert/done'


scp -i ssh-key convert.pl ec2-user@$instance_ip:./videoconvert

ssh -l ec2-user -i ssh-key $instance_ip 'chmod u+x videoconvert/*.pl'

echo "#   You should now type:
ssh -l ec2-user -i ssh-key $instance_ip
#   Then:
screen
#   Then:
cd videoconvert
#   Then:
find ./input | ./convert.pl"
