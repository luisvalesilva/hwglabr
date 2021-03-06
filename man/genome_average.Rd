% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genome_average.R
\name{genome_average}
\alias{genome_average}
\title{Calculate genome-wide average signal}
\usage{
genome_average(inputData)
}
\arguments{
\item{inputData}{List of the 16-chr wiggle data (output of \code{\link{readall_tab}}).
No default.}
}
\value{
A numeric value corresponding to the genome-wide average signal.
}
\description{
Given the wiggle data as a list of 16 chromosomes, this function returns a single
value corresponding to the genome-wide signal average.
}
\examples{
\dontrun{
average_signal <- genome_average(WT)
}
}
