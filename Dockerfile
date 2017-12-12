## Adapted from https://raw.githubusercontent.com/rocker-org/r-devel-san-clang/master/Dockerfile
FROM rocker/hadleyverse
MAINTAINER "Jeremy Leipzig" leipzig@cytovas.com

# snakemake
RUN apt-get -qq update
RUN apt-get install -qqy python3-setuptools python3-docutils python3-flask
RUN easy_install3 snakemake
RUN easy_install3 boto

# Install biocInstaller
RUN R -q -e 'source("http://bioconductor.org/biocLite.R")'

# Install devtools and all deps
RUN install2.r -d TRUE --error devtools \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Install devtools and all deps
RUN install2.r -d TRUE --error devtools \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Attach devtools and testthat to match my local env
RUN echo 'if (interactive()) { \
  suppressMessages(require(devtools)); \
  suppressMessages(require(testthat)) \
}' >> /usr/local/lib/R/etc/Rprofile.site

#tools
RUN apt-get install -qqy libfftw3-3 libfftw3-dev libtiff5-dev

COPY cytovasTools_0.1.0.tar.gz /tmp/cytovasTools.tar.gz
RUN R -q -e 'source("http://bioconductor.org/biocLite.R");biocLite("EBImage");biocLite("flowFP");'
RUN tar xzf /tmp/cytovasTools.tar.gz
RUN R -q -e 'devtools::install("cytovasTools",dependencies=TRUE)'


#ffp
#COPY flowFramePlus.tar.gz /tmp/flowFramePlus.tar.gz
COPY flowFramePlus_0.1.0.tar.gz /tmp/flowFramePlus.tar.gz
# Install the current package
RUN tar xzf /tmp/flowFramePlus.tar.gz
RUN R -q -e 'source("http://bioconductor.org/biocLite.R");biocLite("flowCore");biocLite("flowViz");'
RUN R -q -e 'devtools::install("flowFramePlus",dependencies=TRUE)'


#bt
COPY batchTitration_0.1.1.tar.gz /tmp/batchTitration.tar.gz
RUN tar xzf /tmp/batchTitration.tar.gz
RUN R -q -e 'devtools::install("batchTitration",dependencies=TRUE)'

#snakemake
COPY batchTitration/inst/snakemake/Snakefile /Snakefile

#entry
ENTRYPOINT ["snakemake"]