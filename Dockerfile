## Adapted from https://raw.githubusercontent.com/rocker-org/r-devel-san-clang/master/Dockerfile
## FROM rocker/tidyverse
FROM debian:stretch
MAINTAINER "Jeremy Leipzig" leipzig@cytovas.com

# snakemake
RUN apt-get -qq update
RUN apt-get install -qqy python3-setuptools python3-docutils python3-flask \
                         python3-pip libfftw3-3 libfftw3-dev libtiff5-dev r-base-dev \
                         curl

# Install miniconda to /miniconda
RUN curl -LO https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b
RUN rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

RUN conda config --add channels defaults
RUN conda config --add channels conda-forge
RUN conda config --add channels bioconda

RUN conda install -y r=3.4.1
RUN conda install -y bioconductor-biocinstaller=1.28.0
RUN conda install -y bioconductor-flowcore=1.44.0
RUN conda install -y r-essentials=1.6.0
RUN conda install -y r-devtools=1.13.2
RUN conda install -y snakemake bioconductor-ebimage=4.20.0 bioconductor-flowfp=1.36.0 bioconductor-flowViz=1.42.0
RUN conda install -y -c conda-forge rpy2
RUN conda install -y r-qdaptools
#this is required by bioconductor /miniconda/lib/R/bin/exec/R: error while loading shared libraries: libreadline.so.6
RUN conda install -y -c conda-forge readline=6.2
RUN conda install -y libgfortran

#not sure why bioconductor insists on gtar
RUN conda install -y -c conda-forge tar
RUN ln -s /bin/tar /bin/gtar

#this is for the extra stuff we do
RUN conda install -y -c anaconda boto3


#https://conda-forge.org/docs/conda-forge_gotchas.html#using-multiple-channels
#libicui18n.so.58: cannot open shared object file: No such file or directory
RUN conda install -y -c conda-forge icu
RUN Rscript -e "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl');install.packages(c('littler', 'docopt','ezknitr'));"

#this is not working
RUN ln -s /miniconda/lib/R/library/littler/bin/r /usr/local/bin/r
RUN ln -s /miniconda/lib/R/library/littler/examples/install2.r /usr/local/bin/install2.r 
RUN conda install -y -c conda-forge r-rcurl

#tools
COPY cytovasTools_0.1.0.tar.gz /tmp/cytovasTools.tar.gz
RUN tar xzf /tmp/cytovasTools.tar.gz
RUN R -q -e 'devtools::install("cytovasTools",dependencies=TRUE)'

#ffp
COPY flowFramePlus_0.1.0.tar.gz /tmp/flowFramePlus.tar.gz
RUN tar xzf /tmp/flowFramePlus.tar.gz
RUN R -q -e 'devtools::install("flowFramePlus",dependencies=FALSE)'

#bt
COPY batchTitration_0.1.1.tar.gz /tmp/batchTitration.tar.gz
RUN tar xzf /tmp/batchTitration.tar.gz
RUN R -q -e 'devtools::install("batchTitration",dependencies=TRUE)'

#snakemake
COPY batchTitration/inst/snakemake/Snakefile /Snakefile

#entry
ENTRYPOINT ["snakemake"]

