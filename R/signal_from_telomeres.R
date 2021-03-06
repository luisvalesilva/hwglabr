#' Collect signal from telomeres for all chromosome arms
#'
#' This function allows you to pull out the ChIP signal from all telomeres.\cr
#' The function takes as input the wiggle data as a list of 16 chromosomes.
#' (output of \code{\link{readall_tab}}). \cr\cr
#' \strong{Note:} The SK1 genome annotation is currently not perfect and includes
#' several inconsistencies at telomeric and sub-telomeric regions. This must be kept in
#' mind when analying the data, as it will affect the output of this analysis.\cr
#' \strong{Note:} The fact that some sub-telomeric sequences are incomplete in the
#' SK1 genome means that in some cases we have ChIP-seq data mapping all the way to
#' the very end of the available sequence. This, together with the read extension performed
#' by MACS, leads to some cases where last positions in the wiggle data for the right
#' chromosome arms are higher than the  annotated length of the respective chromosome.
#' This results in negative position values appearing in the output of this function
#' (typically not off by more than 150 bp). The reference SK1 sequence is not reliable
#' in positions close to several telomeres and analyses focusing on sub-telomeric regions
#' should only use data mapped to the S288c reference genome.\cr
#' \cr \cr
#' @param inputData As a list of the 16 chr wiggle data (output of \code{\link{readall_tab}}). No default.
#' @param lengthToCollect Number specifying the length (in bp) of the region to collect signal for,
#' starting form the telomeres. Defaults to 100000 (i.e. 100 kb).
#' @return A list with two elements, each one is itself a list containing the collected
#' signal separately for the right and left arms of the included chromosomes:
#' \enumerate{
#'   \item \code{small_chrs} List of data frames of collected signal for right and
#'   left arms of chromosomes 1, 3 and 6
#'   \item \code{large_chrs} List of data frames of collected signal for right and
#'   left arms of remaining chromosomes
#' }
#' Each data frame has two columns:
#' \enumerate{
#'   \item \code{distance_to_telomere} Distance to telomere in bp
#'   \item \code{signal} ChIP-seq signal
#' }
#' @examples
#' \dontrun{
#' signal_from_telomeres(WT)
#' 
#' signal_from_telomeres(WT, lengthToCollect = 50000)
#' }
#' @export


signal_from_telomeres <- function(inputData, lengthToCollect = 100000) {
  ptm  <- proc.time()
  
  # Check reference genome for both the input data and the gff file; make sure they match
  chrom_S288C <- c("I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                   "XI", "XII", "XIII", "XIV", "XV", "XVI")
  chrom_SK1 <- c('01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
                 '11', '12', '13', '14', '15', '16')
  
  check_S288C <- any(grep('chrI.', names(inputData), fixed = TRUE))
  check_SK1 <- any(grep('chr01.', names(inputData), fixed = TRUE))
  
  if (check_S288C) {
    message('Ref. genome - S288C\n(Chrs numbered using roman numerals)\n')
    chrom <- chrom_S288C
  } else if (check_SK1) {
    message('Ref. genome - SK1\n(Chrs numbered using arabic numerals)\n')
    chrom <- chrom_SK1
  } else stop('Did not recognize reference genome.')
 
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("R package 'dplyr' needed for this function to work. Please install it.\n",
         "install.packages('dplyr')", call. = FALSE)
  }
  
  #----------------------------------------------------------------------------#
  # All data loaded below is internal to the package
  # Generated using 'data-raw/data_internal.R'; stored in 'R/sysdata.rda'
  #----------------------------------------------------------------------------#
  # Load the data:
  if (check_SK1) {
    Cen <- SK1cen
  } else {
    Cen <- S288Ccen
  }
  
  message('Collecting signal...\n')
  
  #----------------------------------------------------------------------------#
  #------------------------- Small chrs: I, III, VI ---------------------------#
  smallChrs <- list()
  chrom_small <- chrom[c(1, 3, 6)]
  
  message(paste0('\nSmall chrs: '))
  for(i in 1:length(chrom_small)) {
    chrNum <- paste0('chr', chrom_small[i])
    message(paste0(chrNum, ' '))
    
    # Index of ChIP data list item corresponding to chrom to analyze
    # Add '.' to make it unique (otherwise e.g. 'chrI' matches 'chrII' too)
    listIndex <- grep(paste0(chrNum, '.'), names(inputData), fixed = TRUE)
    chromData <- inputData[[listIndex]]
    
    #--------------------------- Collect left arm -----------------------------#
    if(!lengthToCollect %in% as.data.frame(chromData)[, 1]) {
      # If the specific position is not present, collect up to the last position
      # before the chosen length that is present in the data
      end <- tail(which(chromData[, 1] < lengthToCollect), 1)
    } else {
      end <- which(chromData[, 1] == lengthToCollect)
    }
    smallChrs[[paste0(chrNum, '_Larm')]] <- chromData[0:end, ]
    colnames(smallChrs[[paste0(chrNum, '_Larm')]]) <- c('distance_to_telomere', 'signal')
    
    #-------------------------- Collect right arm -----------------------------#
    start <- Cen[Cen$Chromosome == chrNum, "LenChr"] - lengthToCollect
    if(!start %in% as.data.frame(chromData)[, 1]) {
      # If the specific position is not present, collect from the first position
      # after the chosen length that is present in the data
      start <- head(which(chromData[, 1] > start), 1)
    } else {
      start <- which(chromData[, 1] == start)
    }
    smallChrs[[paste0(chrNum, '_Rarm')]] <- chromData[start:nrow(chromData), ]
    # Change positions to distance from telomere (start to full length)
    # Add 1 to make 1-indexed (like the left arm)
    end <- Cen[Cen$Chromosome == chrNum, "LenChr"]
    smallChrs[[paste0(chrNum, '_Rarm')]][, 1] <- end - smallChrs[[paste0(chrNum, '_Rarm')]][, 1] + 1
    colnames(smallChrs[[paste0(chrNum, '_Rarm')]]) <- c('distance_to_telomere', 'signal')
  }
  
  
  #----------------------------------------------------------------------------#
  #--------------------- Large chrs: all but I, III, VI -----------------------#
  largeChrs <- list()
  chrom_large <- chrom[-c(1, 3, 6)]
  
  message(paste0('\nLarge chrs: '))
  for(i in 1:length(chrom_large)) {
    chrNum <- paste0('chr', chrom_large[i])
    message(paste0(chrNum, ' '))
    
    # Index of ChIP data list item corresponding to chrom to analyze
    # Add '.' to make it unique (otherwise e.g. 'chrI' matches 'chrII' too)
    listIndex <- grep(paste0(chrNum, '.'), names(inputData), fixed = TRUE)
    chromData <- inputData[[listIndex]]
    
    #--------------------------- Collect left arm -----------------------------#
    if(!lengthToCollect %in% as.data.frame(chromData)[, 1]) {
      # If the specific position is not present, collect up to the last position
      # before the chosen length that is present in the data
      end <- tail(which(chromData[, 1] < lengthToCollect), 1)
    } else {
      end <- which(chromData[, 1] == lengthToCollect)
    }
    largeChrs[[paste0(chrNum, '_Larm')]] <- chromData[0:end, ]
    colnames(largeChrs[[paste0(chrNum, '_Larm')]]) <- c('distance_to_telomere', 'signal')
    
    #-------------------------- Collect right arm -----------------------------#
    start <- Cen[Cen$Chromosome == chrNum, "LenChr"] - lengthToCollect
    if(!start %in% as.data.frame(chromData)[, 1]) {
      # If the specific position is not present, collect from the first position
      # after the chosen length that is present in the data
      start <- head(which(chromData[, 1] > start), 1)
    } else {
      start <- which(chromData[, 1] == start)
    }
    largeChrs[[paste0(chrNum, '_Rarm')]] <- chromData[start:nrow(chromData), ]
    # Change positions to distance from telomere (start to full length)
    # Add 1 to make 1-indexed (like the left arm)
    end <- Cen[Cen$Chromosome == chrNum, "LenChr"]
    largeChrs[[paste0(chrNum, '_Rarm')]][, 1] <- end - largeChrs[[paste0(chrNum, '_Rarm')]][, 1] + 1
    colnames(largeChrs[[paste0(chrNum, '_Rarm')]]) <- c('distance_to_telomere', 'signal')
  }
  
  finalList <- list('small_chrs' = smallChrs, 'large_chrs' = largeChrs)
  message(paste0('\n\nCompleted in ', round((proc.time()[3] - ptm[3]), 2), ' sec.\n'))
  
  return(finalList)
}