# What is this
batch-titration is a container allows for one or more fcs files to be automatically processed (using AWS Batch or other runners). It consists of and R packages, some scripts, and a Dockerfile. It produces an html document.

# How to dockerize batch-titration
```
devtools::build()
```
This will produce a `.tar.gz` in the directory above the package directory
```
cd ..
ln -s batch_titration/Dockerfile .
aws ecr get-login --no-include-email --region us-east-1
# run that
docker build -t cytovas-batch-titration .
docker tag cytovas-batch-titration:latest 205853417430.dkr.ecr.us-east-1.amazonaws.com/cytovas-batch-titration:latest
docker push 205853417430.dkr.ecr.us-east-1.amazonaws.com/cytovas-batch-titration:latest
```

# To run from Amazon ECR
```
aws ecr get-login --no-include-email --region us-east-1
```
(run this login command)

To add local mounts to docker ()
```
docker run -it -v /projects:/projects 205853417430.dkr.ecr.us-east-1.amazonaws.com/cytovas-batch-titration /usr/local/lib/R/bin/R 
```
You can then
```
library("batchTitration")
```
