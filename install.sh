#!/bin/bash

#
# Copyright 2021 Simone Maestri. All rights reserved.
# Simone Maestri <simone.maestri@univr.it>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

PIPELINE_DIR=$(realpath $( dirname "${BASH_SOURCE[0]}" ))
MINICONDA_DIR=$(which conda | sed 's/miniconda3.*$/miniconda3/')
conda config --add channels r
conda config --add channels anaconda
conda config --add channels conda-forge
conda config --add channels bioconda

conda create -n MosaicViewer_env seqtk minimap2 samtools=1.15 ncrf bbmap python=2.7
conda create -n NanoFilt_env NanoFilt bioconductor-biostrings 
ln -s $MINICONDA_DIR"/envs/NanoFilt_env/bin/NanoFilt" $MINICONDA_DIR"/envs/MosaicViewer_env/bin"
ln -s $MINICONDA_DIR"/envs/NanoFilt_env/bin/R" $MINICONDA_DIR"/envs/MosaicViewer_env/bin"
ln -s $MINICONDA_DIR"/envs/NanoFilt_env/bin/Rscript" $MINICONDA_DIR"/envs/MosaicViewer_env/bin"

cd $PIPELINE_DIR

echo -e "\n"
echo "Modify variables PIPELINE_DIR and MINICONDA_DIR in config_MosaicViewer.R"
echo -e "PIPELINE_DIR=\"$PIPELINE_DIR\""
echo -e "MINICONDA_DIR=\"$MINICONDA_DIR\""
echo -e "\n"

