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

args = commandArgs(trailingOnly=TRUE)

if (args[1] == "-h" | args[1] == "--help") {
  cat("", sep = "\n")
  cat(paste0("Usage: Rscript Simplify_reads.R <ncrf_summary_file> <reads_fw> <simplified_reads> <side>"), sep = "\n")
  cat(paste0("<ncrf_summary_file>: summary file produced by NCRF"), sep = "\n")
  cat(paste0("<reads_fw>: reads in forward orientation in fasta format, used for NCRF annotation"), sep = "\n")
  cat(paste0("<simplified_reads>: output file with simplified reads, optional [~/Simplified_reads.fasta]"), sep = "\n")
  cat(paste0("<alignment side>: side of the alignment (left or right), optional [left]"), sep = "\n")
  stop(simpleError(sprintf("\r%s\r", paste(rep(" ", getOption("width")-1L), collapse=" "))))
}

if (length(args) == 2) {
  Repeats_summary_file <- args[1]
  Reads_file <- args[2]
  Output_file <- paste0("~/Simplified_reads.fasta")
  Alignment_side <- "left"
} else if (length(args) == 3) {
  Repeats_summary_file <- args[1]
  Reads_file <- args[2]
  Output_file <- args[3]
  Alignment_side <- "left"
} else if (length(args) == 4) {
  Repeats_summary_file <- args[1]
  Reads_file <- args[2]
  Output_file <- args[3]
  Alignment_side <- args[4]
} else {
  stop("At least ncrf_summary_file, reads_fw input arguments must be provided")
}

suppressMessages(require("Biostrings"))

fnlist <- function(x, Output_file) {
  z <- deparse(substitute(x))
  seq_names = names(x)
  row_len <- 50000
  for (i in seq_along(x) ){
    num_rows_curr <- ceiling(nchar(x[[i]])/row_len)
    if (i == 1) {
      cat(seq_names[i], "\n", file = Output_file, append = FALSE)
    } else {
      cat(seq_names[i], "\n", file = Output_file, append = TRUE)
    }
    for (j in 1:num_rows_curr) {
      cat(substr(x[[i]], start = (j - 1)*row_len + 1, stop = j*row_len), "\n", file = Output_file, append = TRUE)
    }
  }
}

Repeats_summary <- read.table(file = Repeats_summary_file, stringsAsFactors = FALSE, fill = TRUE)
Reads_obj <- readDNAStringSet(Reads_file, "fasta")

Repeat_motif <- c()
Read_name <- c()
Repeat_length <- c()
Read_length <- c()
Repeat_start <- c()
Repeat_end <- c()
Repeat_motif_tmp <- Repeats_summary[, 2]
Read_name_tmp <- Repeats_summary[, 3]
Repeat_start_tmp <- Repeats_summary[, 4]
Repeat_end_tmp <- Repeats_summary[, 5]
Read_length_tmp <- Repeats_summary[, 7]
Repeat_length_tmp <- Repeats_summary[, 8]

for (i in 1:length(unique(Read_name_tmp))) {
  ind_curr <- which(Read_name_tmp == unique(Read_name_tmp)[i])
  Read_name <- c(Read_name, Read_name_tmp[ind_curr])
  Repeat_length <- c(Repeat_length, Repeats_summary[ind_curr, 8])
  Read_length <- c(Read_length, Repeats_summary[ind_curr, 7])
  Repeat_start <- c(Repeat_start, Repeats_summary[ind_curr, 4] + 1)
  Repeat_end <- c(Repeat_end, Repeats_summary[ind_curr, 5])
  counter <- 1
  Repeat_motif_tmp_curr <- Repeat_motif_tmp[which(Read_name_tmp == unique(Read_name_tmp)[i])]
  if (length(which(duplicated(Repeat_motif_tmp_curr))) > 0) {
    ind_dup <- which(duplicated(Repeat_motif_tmp_curr))
    for (k in 1:length(Repeat_motif_tmp_curr)) {
      if (k %in% ind_dup) {
        counter <- counter + 1
        Repeat_motif_tmp_curr[k] <- paste0(Repeat_motif_tmp_curr[k])
      } else {
        Repeat_motif_tmp_curr[k] <- Repeat_motif_tmp_curr[k]
      }
    }
    Repeat_motif <- c(Repeat_motif, Repeat_motif_tmp_curr)
  } else {
    Repeat_motif <- c(Repeat_motif, Repeat_motif_tmp_curr)
  }
}

Repeats_df <- data.frame(Motif = Repeat_motif, Read = Read_name, Length = Read_length, Rep_start = Repeat_start, Rep_end = Repeat_end)

Reads_simplified <- list()

min_left_flanking <- 50
min_right_flanking <- 50

Read_name_unique <- unique(Read_name)
for (i in 1:length(Read_name_unique)) {
  #N -> other
  #G -> CGG
  Read_name_curr <- Read_name_unique[i]
  ind_curr <- which(Read_name == Read_name_unique[i])
  ind_curr_fasta <- which(names(Reads_obj) == Read_name_curr)
  Read_seq_curr <- Reads_obj[ind_curr_fasta]
  Reads_simplified_curr <- rep(x = "N", times = Read_length[ind_curr[1]])
  #skip the read if performing a left alignment and no repeat starts after min_left_flanking from the beginning of the read, or if performing a right alignment and no repeat ends before min_right_flanking from the end of the read
  if (Alignment_side == "left" && length(Repeat_start[ind_curr][which(Repeat_start[ind_curr] > min_left_flanking)]) == 0 || Alignment_side == "right" && length(Repeat_end[ind_curr][which(Repeat_end[ind_curr] < (nchar(Read_seq_curr) - min_right_flanking))]) == 0) {
    #skip read
    Reads_simplified_curr <- Read_seq_curr
  } else {
    if (Alignment_side == "left") {
      first_rep_coord <- min(Repeat_start[ind_curr][which(Repeat_start[ind_curr] > min_left_flanking)])
      left_flanking_curr <- substr(x = Read_seq_curr, start = 1, stop = first_rep_coord)
      Reads_simplified_curr[1:nchar(left_flanking_curr)] <- unlist(strsplit(left_flanking_curr, split = ""))
    } else {
      last_rep_coord <- max(Repeat_end[ind_curr][which(Repeat_end[ind_curr] < (nchar(Read_seq_curr) - min_right_flanking))])
      ind_last_rep <- which(Repeat_end[ind_curr] == last_rep_coord)
      right_flanking_curr <- substr(x = Read_seq_curr, start = last_rep_coord, stop = nchar(Read_seq_curr))
      Reads_simplified_curr[last_rep_coord:nchar(Read_seq_curr)] <- unlist(strsplit(right_flanking_curr, split = ""))
    }
    for (k in ind_curr) {
      Repeat_motif_curr <- Repeat_motif[k]
      if (Repeat_motif[k] == "CGG_repeat") {
        Reads_simplified_curr[Repeat_start[k]:Repeat_end[k]] <- "G"
      }
    }
  }
  Reads_simplified[[i]] <- paste0(Reads_simplified_curr, collapse = "")
}
names(Reads_simplified) <- paste0(">", Read_name_unique)
fnlist(Reads_simplified, Output_file)
