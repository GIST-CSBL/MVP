mvp_env <- new.env(parent = emptyenv())

#' Apply pairwise (naive) method to handle dirty data such as duplicate record
#' and missing value problem
#'
#' @param dt Input data frame (data.table)
#' @param key_cols Key (m/z, RT ...) column numbers
#' @param key_thrsh Key (m/z, RT ...) column threshold with same order key_cols
#' @param intensity_cols Intensity column numbers
#' @param conformity_thrsh Conformity threshold
#'
#' @return Dirty data-free data frame (data.table)
apply_pairwise_method <- function(dt, key_cols, key_thrsh, intensity_cols,
                                  conformity_thrsh) {
  before_processed_dt <- dt
  after_processed_dt <- NULL

  iteration <- 1
  while (TRUE) {
    print(stringr::str_c("Start Iteration ", iteration))
    before_processed_dt <- arrange_data_using_key(before_processed_dt, key_cols)
    after_processed_dt <- process_pairwise_merge(before_processed_dt,
                                                 key_cols,
                                                 key_thrsh,
                                                 intensity_cols,
                                                 conformity_thrsh)
    print(stringr::str_c("# of records (Before): ",
                         nrow(before_processed_dt),
                         " -> # of records (After): ",
                         nrow(after_processed_dt)))
    if (identical(all.equal(before_processed_dt, after_processed_dt), TRUE)) {
      break
    } else {
      before_processed_dt <- after_processed_dt
    }
    iteration <- iteration + 1
  }
  return(after_processed_dt)
}

#' Pairwise merge 1 iteration and return after 1 iteration result
#'
#' @param dt Input data frame (data.table)
#' @param conformity_thrsh conformity threshold
#' @param key_cols Key (m/z, RT ...) column numbers
#' @param key_thrshs Key (m/z, RT ...) column thresholds
#' @param intensity_cols Intensity column numbers
#'
#' @return After one iteration result
#' @importFrom utils txtProgressBar setTxtProgressBar
process_pairwise_merge <- function(dt, key_cols, key_thrshs,
                                   intensity_cols, conformity_thrsh) {
  num_of_records <- nrow(dt)
  mvp_env$dt <- data.table::copy(dt)
  mvp_env$already_used <- logical(num_of_records)
  final_extracting_indexes <- integer()

  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {
    if (mvp_env$already_used[current_index]) {
      next
    }

    if (current_index == num_of_records) {
      mvp_env$already_used[current_index] <- T
      final_extracting_indexes <- c(final_extracting_indexes, current_index)
      break
    }

    candidate_indexes <- extract_duplicate_candidate(current_index, key_cols,
                                                     key_thrshs)
    best_matching_idx <- find_best_similar_record(current_index,
                                                  candidate_indexes,
                                                  intensity_cols,
                                                  conformity_thrsh)
    if (is.null(best_matching_idx)) {
      mvp_env$already_used[current_index] <- T
    } else {
      mvp_env$already_used[c(current_index, best_matching_idx)] <- T
      merge_pairwise_record(current_index, best_matching_idx, intensity_cols)
    }

    final_extracting_indexes <- c(final_extracting_indexes, current_index)
    setTxtProgressBar(pb, current_index)
  }
  close(pb)

  return(mvp_env$dt[final_extracting_indexes])
}

#' In pairwise (naive) merging, find best similar record in candidate records
#'
#' @param current_index Current record index
#' @param candidate_indexes Candidate record indexes
#' @param intensity_cols Intensity column numbers
#' @param conformity_thrsh Conformity threshold
#'
#' @return Best similar record index with current record index
find_best_similar_record <- function(current_index, candidate_indexes,
                                     intensity_cols, conformity_thrsh) {
  similarity_vector <- numeric()
  for (candidate_index in candidate_indexes) {
    similarity <- compute_intensity_similarity(current_index, candidate_index,
                                               intensity_cols)
    similarity_vector <- c(similarity_vector, similarity)
  }

  best_similar_index <- NULL
  if (length(similarity_vector) == 0) {
    return(best_similar_index)
  }

  if (max(similarity_vector) > conformity_thrsh) {
    temp <- which.max(similarity_vector)
    best_similar_index <- candidate_indexes[temp]
  }

  return(best_similar_index)
}

#' Merge pairwise records (two records), manipulate non-intensity part and
#' intensity part
#'
#' @param current_index Current record index
#' @param matching_index Best similar record index
#' @param intensity_cols Intensity column numbers
merge_pairwise_record <- function(current_index, matching_index,
                                  intensity_cols) {
  total_cols <- 1:ncol(mvp_env$dt)
  non_intensity_cols <- find_non_intensity_cols(total_cols, intensity_cols)

  for (non_intensity_col in non_intensity_cols) {
    current_record_value <- mvp_env$dt[[non_intensity_col]][current_index]
    matching_record_value <- mvp_env$dt[[non_intensity_col]][matching_index]

    if (is.character(current_record_value)) {
      merged_value <- stringr::str_c(current_record_value,
                                     matching_record_value, sep = ":")
    } else {
      merged_value <- max(current_record_value, matching_record_value)
    }

    data.table::set(mvp_env$dt, i = current_index, j = non_intensity_col,
                    value = merged_value)
  }

  for (intensity_col in intensity_cols) {
    current_record_value <- mvp_env$dt[[intensity_col]][current_index]
    matching_record_value <- mvp_env$dt[[intensity_col]][matching_index]

    if (!is.na(current_record_value) || !is.na(matching_record_value)) {
      merged_value <- max(current_record_value, matching_record_value,
                          na.rm = T)
      data.table::set(mvp_env$dt, i = current_index, j = intensity_col,
                      merged_value)
    }
  }
}
