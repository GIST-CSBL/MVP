% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/process_pairwise_method.R
\name{find_best_similar_record}
\alias{find_best_similar_record}
\title{In pairwise (naive) merging, find best similar record in candidate records}
\usage{
find_best_similar_record(current_index, candidate_indexes, intensity_cols,
  conformity_thrsh)
}
\arguments{
\item{current_index}{Current record index}

\item{candidate_indexes}{Candidate record indexes}

\item{intensity_cols}{Intensity column numbers}

\item{conformity_thrsh}{Conformity threshold}
}
\value{
Best similar record index with current record index
}
\description{
In pairwise (naive) merging, find best similar record in candidate records
}

