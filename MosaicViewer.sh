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
source $PIPELINE_DIR"/config_MosaicViewer.sh"

PR_FW=$($SAMTOOLS faidx $REFERENCE $FW_PRIMER_COORD | $SEQTK seq -A - | grep -v ">")
PR_RV=$($SAMTOOLS faidx $REFERENCE $RV_PRIMER_COORD | $SEQTK seq -A - | grep -v ">")

REF_FILENAME=$GENE_NAME"_masked_reference_"$SIDE".fasta"
REF_NAME=$GENE_NAME"_masked_reference_"$SIDE

N_SEQ=$(printf 'N%.0s' {1..3000})

#generate reference sequence
if [[ "$SIDE" == "left" && "$GENE_STRAND" == "+" ]]; then
  PR_FW_FULL=$($SAMTOOLS faidx $REFERENCE $FW_PRIMER_COORD | $SEQTK seq -A - | grep -v ">")
  PR_RV_FULL=$($SAMTOOLS faidx $REFERENCE $FLANKING_COORD_TRIMMED | $SEQTK seq -A - | grep -v ">")
  REF_TMP=$($SAMTOOLS faidx $REFERENCE $FLANKING_REF_COORD | $SEQTK seq -A - | grep -v ">")
  REF="$REF_TMP$N_SEQ"
elif [[ "$SIDE" == "right" && "$GENE_STRAND" == "+" ]]; then
  PR_FW_FULL=$($SAMTOOLS faidx $REFERENCE $FLANKING_COORD_TRIMMED | $SEQTK seq -A - | grep -v ">")
  PR_RV_FULL=$($SAMTOOLS faidx $REFERENCE $RV_PRIMER_COORD | $SEQTK seq -A - | grep -v ">")
  REF_TMP=$($SAMTOOLS faidx $REFERENCE $FLANKING_REF_COORD | $SEQTK seq -A - | grep -v ">")
  REF="$N_SEQ$REF_TMP"
elif [[ "$SIDE" == "left" && "$GENE_STRAND" == "-" ]]; then
  PR_FW_FULL=$($SAMTOOLS faidx $REFERENCE $RV_PRIMER_COORD | $SEQTK seq -A -r - | grep -v ">")
  PR_RV_FULL=$($SAMTOOLS faidx $REFERENCE $FLANKING_COORD_TRIMMED | $SEQTK seq -A -r - | grep -v ">")
  REF_TMP=$($SAMTOOLS faidx $REFERENCE $FLANKING_REF_COORD | $SEQTK seq -A -r - | grep -v ">")
  REF="$REF_TMP$N_SEQ"
else
  PR_FW_FULL=$($SAMTOOLS faidx $REFERENCE $FLANKING_COORD_TRIMMED | $SEQTK seq -A -r - | grep -v ">")
  PR_RV_FULL=$($SAMTOOLS faidx $REFERENCE $FW_PRIMER_COORD | $SEQTK seq -A -r - | grep -v ">")
  REF_TMP=$($SAMTOOLS faidx $REFERENCE $FLANKING_REF_COORD | $SEQTK seq -A -r - | grep -v ">")
  REF="$N_SEQ$REF_TMP"
fi

echo -e ">$REF_NAME\n$REF" > $REF_FILENAME

SAMPLE_NAME=$(echo $(basename $FASTQ) | sed 's/\.fastq//')

#extract complete reads
SAM_FILE_ONE=$SAMPLE_NAME"_in_silico_pcr_one.sam"
SAM_FILE_TWO=$SAMPLE_NAME"_in_silico_pcr_two.sam"
$MSA in=$FASTQ out=$SAM_FILE_ONE literal=$PR_FW qin=33 cutoff=$THR
$MSA in=$FASTQ out=$SAM_FILE_TWO literal=$PR_RV qin=33 cutoff=$THR
$CUTPRIMERS in=$FASTQ out=$SAMPLE_NAME"_trimmed_two_alleles_wflank.fastq" sam1=$SAM_FILE_ONE sam2=$SAM_FILE_TWO qin=33 fake=f include=t fixjunk

cat $SAMPLE_NAME"_trimmed_two_alleles_wflank.fastq" | $NANOFILT -l $MINLENGTH > $SAMPLE_NAME"_trimmed_wflank.fastq"

#trim flanking regions
SAM_FILE_ONE_REP=$SAMPLE_NAME"_in_silico_pcr_one_noflank.sam"
SAM_FILE_TWO_REP=$SAMPLE_NAME"_in_silico_pcr_two_noflank.sam"
$MSA in=$SAMPLE_NAME"_trimmed_wflank.fastq" out=$SAM_FILE_ONE_REP literal=$PR_FW_FULL qin=33 cutoff=$THR
$MSA in=$SAMPLE_NAME"_trimmed_wflank.fastq" out=$SAM_FILE_TWO_REP literal=$PR_RV_FULL qin=33 cutoff=$THR
$CUTPRIMERS in=$SAMPLE_NAME"_trimmed_wflank.fastq" out=$SAMPLE_NAME"_trimmed.fastq" sam1=$SAM_FILE_ONE_REP sam2=$SAM_FILE_TWO_REP qin=33 fake=f include=f fixjunk

$SEQTK seq -A $SAMPLE_NAME"_trimmed.fastq" | grep "^>" | sed 's/>//' | cut -d ' ' -f1 | sort > $SAMPLE_NAME"_reads_IDs.txt"

#map to reference
$MINIMAP2 -ax map-ont -k5 --MD $REF_FILENAME $SAMPLE_NAME"_trimmed.fastq" | $SAMTOOLS view -h -F2308 | $SAMTOOLS sort -o $SAMPLE_NAME"_trimmed_"$SIDE".bam" -T reads.tmp
$SAMTOOLS index $SAMPLE_NAME"_trimmed_"$SIDE".bam"

#extract fasta from bam in forward orientation
$SAMTOOLS view $SAMPLE_NAME"_trimmed_"$SIDE".bam" -F2308 | awk '{OFS="\t"; print ">"$1"\n"$10}' - > $SAMPLE_NAME"_trimmed_"$SIDE"_fw.fasta"

#run NCRF
cat $SAMPLE_NAME"_trimmed_"$SIDE"_fw.fasta" | $NCRF_DIR"/NCRF" --scoring=nanopore --minlength=12 CGG_repeat:CGG --minmratio=0.90 --stats=events --positionalevents > $SAMPLE_NAME"_"$SIDE"_CGG.ncrf"
$NCRF_DIR"/ncrf_cat.py" $SAMPLE_NAME"_"$SIDE"_CGG.ncrf" | $NCRF_DIR"/ncrf_sort.py" --sortby=name | $NCRF_DIR"/ncrf_summary.py" | grep -P "^#|\+" > $SAMPLE_NAME"_trimmed_"$SIDE"_fw.ncrf.summary"

#extract ID of reads that mapped as RC
$SAMTOOLS view -f16 $SAMPLE_NAME"_trimmed_"$SIDE".bam" | cut -f1 | sort > $SAMPLE_NAME"_"$SIDE"_reads_trimmed_to_rc_IDs.txt"

#extract ID of reads that mapped on the forward strand
grep -F -x -v -f $SAMPLE_NAME"_"$SIDE"_reads_trimmed_to_rc_IDs.txt" $SAMPLE_NAME"_reads_IDs.txt" > $SAMPLE_NAME"_"$SIDE"_reads_trimmed_ok_IDs.txt"

#generate simplified reads
$SIMPLIFY_READS "./"$SAMPLE_NAME"_trimmed_"$SIDE"_fw.ncrf.summary" "./"$SAMPLE_NAME"_trimmed_"$SIDE"_fw.fasta" "./"$SAMPLE_NAME"_trimmed_"$SIDE"_fw_simplified.fasta" $SIDE
$SEQTK subseq $SAMPLE_NAME"_trimmed_"$SIDE"_fw_simplified.fasta" $SAMPLE_NAME"_"$SIDE"_reads_trimmed_ok_IDs.txt" -l 100000 > $SAMPLE_NAME"_trimmed_"$SIDE"_fw_simplified_ok.fasta"
$SEQTK subseq $SAMPLE_NAME"_trimmed_"$SIDE"_fw_simplified.fasta" $SAMPLE_NAME"_"$SIDE"_reads_trimmed_to_rc_IDs.txt" -l 100000 | $SEQTK seq -A -r -  > $SAMPLE_NAME"_trimmed_"$SIDE"_rv_simplified_ok.fasta"
cat $SAMPLE_NAME"_trimmed_"$SIDE"_fw_simplified_ok.fasta" $SAMPLE_NAME"_trimmed_"$SIDE"_rv_simplified_ok.fasta" > $SAMPLE_NAME"_trimmed_simplified_"$SIDE"_final.fasta"
$MINIMAP2 -ax map-ont -k5 --MD  $REF_FILENAME $SAMPLE_NAME"_trimmed_simplified_"$SIDE"_final.fasta" | $SAMTOOLS sort -o $SAMPLE_NAME"_trimmed_simplified_"$SIDE"_final.bam"
$SAMTOOLS index $SAMPLE_NAME"_trimmed_simplified_"$SIDE"_final.bam"
