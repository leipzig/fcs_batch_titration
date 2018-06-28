# What is this
batch-titration is a container allows for one or more fcs files to be automatically processed (using AWS Batch or other runners). It consists of an R package, some scripts, and a Dockerfile. It produces an html document.

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

As an aside, to clean up docker
```
docker ps -aq -f status=exited
docker ps -aq --no-trunc | xargs docker rm
docker images -q --filter dangling=true | xargs docker rmi
```

To test locally and override snakemake
```
docker run -it --entrypoint "/bin/bash" -e AWS_ACCESS_KEY_ID="your access key" -e AWS_SECRET_ACCESS_KEY="your secret" -e CONFIG_KEY="40cfa138-b869-4a16-a854-e50636a5e43e.yaml" cytovas-batch-titration
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

To queue a AWS batch job. The `CONFIG_KEY` refers to a config file in the titration config bucket.
```
aws batch submit-job --job-name example --job-queue fcs-batch-queue  --job-definition batch_titration_or_check --container-overrides '{"environment":[{"name":"CONFIG_KEY","value":"40cfa138-b869-4a16-a854-e50636a5e43e.yaml"}]}'
```

List the jobs:
```
aws batch list-jobs --job-queue arn:aws:batch:us-east-1:205853417430:job-queue/fcs-batch-queue
```

To monitor a job
```
aws batch describe-jobs --jobs 7bcd65c8-a74d-4c26-a1aa-a5bb716b4963
```
