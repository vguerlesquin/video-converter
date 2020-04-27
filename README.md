# video-converter
Everything to massively convert videos using AWS EC2 spot instance

#Pre-requisites
Your videos have to be on a EFS, in `/input` directory. Converted files will be put in `/output` directory, and old one will be moved to `/done` directory. I personally sync my videos from my Synology NAS to a S3 Bucket, and then do the sync to an EFS using AWS S3 CLI.

Terraform should be installed and your `AWS_ACCESS_KEY_ID` and `AWS_ACCESS_SECRET_KEY_ID` properly set up.

#Usage
1. Create an EFS where you will store your videos to be converted in `/input`.
2. Replace in convert.bash the value of `efs_mountpoint` with something like `'fs-something.efs.ca-central-1.amazonaws.com'`.
3. Launch `convert.bash` and at the end, launch manually the command asked by the script.
4. Don't forget to do a `terraform destroy` once you're done.


#Changing default configuration.
- EC2 instance type can be changed in `ec2_host.tf`. `c5.24xlarge` instance with spot pricing model fits well for large amount of files and 10 parallels threads. Smaller instance type will may require less threads, since one limitation could be the EFS throughput. Proposed configuration works well, though.
- Number of threads can be changed in `convert.pl` script.

#Why ca-central-1 ?
`ca-central-1` is around Montréal, QC, Canada, where electricity is exclusively hydro-electricity, which means clean & carbon-zero. Think about it.
