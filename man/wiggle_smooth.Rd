% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wiggle_smooth.R
\name{wiggle_smooth}
\alias{wiggle_smooth}
\title{Sliding window smooth of wiggle data}
\usage{
wiggle_smooth(wiggleData, chrNumber, bandwidth = 200, useKsmooth = FALSE)
}
\arguments{
\item{wiggleData}{Accepts input in one of the following formats:
\enumerate{
  \item An R list of the 16 chromosome wiggle data (output of \code{readall_tab()}).
  \item An element of an R list of the form described in the first item above.
  Can be extracted with either '[]' or '[[]]'.
  \item An R data frame in the same format as the individual chromosome data
  frames composing the list described in the first item above.
  }
  No default.}

\item{chrNumber}{An integer representing the chromosome to smooth. Will be ignored
in case the provided \code{wiggleData} is not a list of data for the 16 chromosomes.
No default.}

\item{bandwidth}{An integer representing the length of the smoothing window in bp
(or the Gaussian kernel bandwith, if \code{useKsmooth = TRUE}). Defaults to \code{200}.}

\item{useKsmooth}{Boolean indicating choice of smoothing function:
\enumerate{
  \item \code{useKsmooth = FALSE}: use a simple sliding window smoother. Smoothing is performed by
  sliding a window of the specified size (\code{bandwidth} argument) over all genomic positions in
  the data and replacing the position values by the middle position and the signal values by
  their mean.
  \item \code{useKsmooth = TRUE}: use a Gaussian Kernel Regression Smoother. Smoothing is performed
  using function \code{ksmooth()} from 'stats' package using the default \code{normal} kernel and the
  specified bandwith.
  }
  Defaults to \code{FALSE}.}
}
\value{
An R data frame with two columns: genome position and smoothed signal.
}
\description{
This function allows you to smooth wiggle data using a sliding window.
}
\examples{
\dontrun{
wiggle_smooth(WT, 1, 200)

wiggle_smooth(rec8, 16, 100)

wiggle_smooth(WT[[5]], bandwidth = 1000)

wiggle_smooth(WT[[9]], bandwidth = 1000, useKsmooth = T)
}
}
