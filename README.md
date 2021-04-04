# MosaicViewer_FMR1

**MosaicViewer_FMR1** is a pipeline for schematic visualization of alleles with somatic mosaicism. Due to mosaicism, long sequencing reads can not be collapsed into an accurate consensus sequence. Therefore, only repeat annotation of each single read can be performed. MosaicViewer_FMR1 integrates tool for performing repeat annotation of noisy long reads, performs alignment to left and right flanking regions, and generates "simplified" reads, for easier identification of alternative motifs in IGV visualization. The pipeline has only been used for FMR1 alleles, but its applicability can be extended with minor modification.

<p align="center">
  <img src="Figures/MosaicViewer.png" alt="drawing" width="400" title="MosaicViewer_pipeline">
</p>


## Getting started

**Prerequisites**

* Miniconda3.
Tested with conda 4.9.2.
```which conda``` should return the path to the executable.
If you don't have Miniconda3 installed, you could download and install it with:
```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod 755 Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh
```

* A fastq file containing reads from one sample. Tested with files produced with Guppy v4.2.
* A fasta file containing reference sequence (e.g. hg38)
* Coordinates of flanking regions (e.g. regions flanking the repeat)

**Installation**

```
git clone https://github.com/MaestSi/MosaicViewer_FMR1.git
cd MosaicViewer_FMR1
chmod 755 *
./install.sh
```

A conda environment named _MosaicViewer\_env_ is created, where seqtk, minimap2, samtools, NoiseCancellingRepeatFinder, BBMap and R with package Biostrings are installed. Another conda environment named _NanoFilt\_env_ is created, where NanoFilt is installed. 
Then, you can open the **config_MosaicViewer.sh** file with a text editor and set the variables _PIPELINE_DIR_ and _MINICONDA_DIR_ to the value suggested by the installation step.

## Usage
As a first step, open the **config_MosaicViewer.sh** file with a text editor and set all the variables. Depending on the reference coordinates set in the file, in-silico PCR primers and flanking regions for performing left or right alignment are extracted.

<p align="center">
  <img src="Figures/FMR1_left_right_alignment.png" alt="drawing" width="800" title="FMR1_left_right_alignment">
</p>

**MosaicViewer.sh**

Usage: ./MosaicViewer.sh

Note: the file **config_MosaicViewer.sh** should be in the same directory. It currently supports CGG repeat motif.

Outputs:

* $SAMPLE_NAME"\_trimmed\_"$SIDE".bam": bam file containing expanded reads aligned to $GENE_NAME"\_masked\_reference\_"$SIDE".fasta"
* $SAMPLE_NAME"\_trimmed\_simplified\_"$SIDE"\_final.bam": bam file containing simplified version of expanded reads aligned to $GENE_NAME"\_masked\_reference\_"$SIDE".fasta", where the sequence of each identified repeat has been replaced with a single repeated nucleotide (CGG -> GGG; other -> N)
* Other temporary files

## Results visualization

For example, this is how the right alignment of trimmed reads (with or without colouring based on annotated repeats) would look like.

<p align="center">
  <img src="Figures/MosaicViewer_output_example.png" alt="drawing" width="800" title="MosaicViewer_output_example">
</p>
