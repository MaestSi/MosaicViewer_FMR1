FROM continuumio/miniconda3

########### set variables
ENV DEBIAN_FRONTEND noninteractive

########## generate working directories
RUN mkdir /home/tools

######### dependencies
RUN apt-get update -qq \
    && apt-get install -y \
    build-essential \
    wget \
    unzip \
    bzip2 \
    git \
    libidn11* \
    nano \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

############################################################ install MosaicViewer_FMR1
WORKDIR /home/tools/

RUN git clone https://github.com/MaestSi/MosaicViewer_FMR1.git
WORKDIR /home/tools/MosaicViewer_FMR1
RUN chmod 755 *

RUN sed -i 's/PIPELINE_DIR=.*/PIPELINE_DIR=\"\/home\/tools\/MosaicViewer_FMR1\/\"/' config_MosaicViewer.sh
RUN sed -i 's/MINICONDA_DIR=.*/MINICONDA_DIR=\"\/opt\/conda\/\"/' config_MosaicViewer.sh

RUN conda config --add channels r && \
conda config --add channels anaconda && \
conda config --add channels conda-forge && \
conda config --add channels bioconda

RUN conda create -n MosaicViewer_env seqtk minimap2 samtools=1.15 ncrf bbmap python=2.7
RUN conda create -n NanoFilt_env NanoFilt bioconductor-biostrings 
RUN ln -s /opt/conda/envs/NanoFilt_env/bin/NanoFilt /opt/conda/envs/MosaicViewer_env/bin
RUN ln -s /opt/conda/envs/NanoFilt_env/bin/R /opt/conda/envs/MosaicViewer_env/bin
RUN ln -s /opt/conda/envs/NanoFilt_env/bin/Rscript /opt/conda/envs/MosaicViewer_env/bin

WORKDIR /home/
