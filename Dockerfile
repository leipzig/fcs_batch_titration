## Adapted from https://raw.githubusercontent.com/rocker-org/r-devel-san-clang/master/Dockerfile
FROM rocker/hadleyverse
MAINTAINER "Jeremy Leipzig" leipzig@cytovas.com

# Install biocInstaller
RUN R -q -e 'source("http://bioconductor.org/biocLite.R")'

# Install devtools and all deps
RUN install2.r -d TRUE --error devtools \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Attach devtools and testthat to match my local env
RUN echo 'if (interactive()) { \
  suppressMessages(require(devtools)); \
  suppressMessages(require(testthat)) \
}' >> /usr/local/lib/R/etc/Rprofile.site

#ffp
COPY flowFramePlus_0.1.0.tar.gz /tmp/flowFramePlus_0.1.0.tar.gz
# Install the current package
RUN tar xzf /tmp/flowFramePlus_0.1.0.tar.gz
RUN R -q -e 'source("http://bioconductor.org/biocLite.R");biocLite("flowCore");biocLite("flowViz");'
RUN R -q -e 'devtools::install("flowFramePlus",dependencies=TRUE)'

#bt
COPY batchTitration_0.1.0.tar.gz /tmp/batchTitration_0.1.0.tar.gz
RUN tar xzf /tmp/batchTitration_0.1.0.tar.gz
RUN R -q -e 'devtools::install("batchTitration",dependencies=TRUE)'

