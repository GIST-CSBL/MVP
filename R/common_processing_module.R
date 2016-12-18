#' Rearrange data frame before processing MVP
#'
#' @param dt Data frame (data.table) that want to rearrange using keys
#' @param key_cols Key (m/z, retention time) column numbers
#'
#' @return Rearranged data frame (data.table)
arrange_data_using_key <- function(dt, key_cols) {
  key_names <- colnames(dt)[key_cols]
  order <- rep.int(1, length(key_names))
  return(data.table::setorderv(dt, key_names, order))
}

#' Extract duplicate candidates related current record (using index number)
#'
#' @param current_index Current record index
#' @param key_cols Key (m/z, RT can be both or only one) column numbers
#' @param key_thrshs Key (m/z, RT same order of key_cols) column thresholds
#'
#' @return Duplicate candidates related to current record
extract_duplicate_candidate <- function(current_index, key_cols, key_thrshs) {
  candidate_indexes <- integer()

  num_of_records <- nrow(mvp_env$dt)
  for (candidate_index in (current_index + 1):num_of_records) {
    if (mvp_env$already_used[candidate_index]) {
      next
    }

    condition_state <- inspect_conditions(current_index, candidate_index,
                                          key_cols, key_thrshs)

    if (condition_state == "Unsatisfy_Primary_Condition") {
      break
    } else if (condition_state == "Satisfy_All_Condition") {
      candidate_indexes <- c(candidate_indexes, candidate_index)
    } else if (condition_state == "Unsatisfy_Minor_Condition") {
      next
    }
  }

  # Todo(geunho): Should be removed, after testing
  # if (length(candidate_indexes) == 3) {
  #   print(current_index)
  #   print(candidate_indexes)
  # }

  return(candidate_indexes)
}

#' Inspect current record and candidate record are satisfied with conditions
#'
#' @param current_index Current record index
#' @param candidate_index Candidate record index
#' @param key_cols Key (m/z, RT) column numbers
#' @param key_thrshs Key (m/z, RT) column thresholds
#'
#' @return Condition statement string
inspect_conditions <- function(current_index, candidate_index,
                               key_cols, key_thrshs) {
  satisfy_all_condition <- "Satisfy_All_Condition"
  unsatisfy_primary_condition <- "Unsatisfy_Primary_Condition"
  unsatisfy_minor_condition <- "Unsatisfy_Minor_Condition"

  is_condition_satisfied <- check_condition(current_index, candidate_index,
                                            key_cols[1], key_thrshs[1])

  if (!is_condition_satisfied) {
    return(unsatisfy_primary_condition)
  }

  if (is_condition_satisfied && length(key_cols) == 1) {
    return(satisfy_all_condition)
  }

  condition_flag <- T
  for (current_key in 2:length(key_cols)) {
    is_condition_satisfied <- check_condition(current_index, candidate_index,
                                              key_cols[current_key],
                                              key_thrshs[current_key])
    if (!is_condition_satisfied) {
      condition_flag <- F
      break
    }
  }

  if (condition_flag) {
    return(satisfy_all_condition)
  } else {
    return(unsatisfy_minor_condition)
  }
}

#' Check condition is satisfied or not.
#' If value difference is less than threshold than condition is satisfied
#'
#' @param current_index Current record index
#' @param candidate_index Candidate record index
#' @param key_col Key (m/z, RT ...) column number
#' @param key_thrsh Key (m/z, RT ...) column threshold
#'
#' @return If condition satisfied thant return TRUE, else return FALSE
check_condition <- function(current_index, candidate_index,
                            key_col, key_thrsh) {
  current_record_value <- mvp_env$dt[[key_col]][current_index]
  candidate_record_value <- mvp_env$dt[[key_col]][candidate_index]

  value_difference <- abs(current_record_value - candidate_record_value)
  return(ifelse(value_difference < key_thrsh, TRUE, FALSE))
}

#' Compute pairwise similarity of two records (current and candidate)
#'
#' @param current_index Current record index
#' @param candidate_index Candidate record index
#' @param intensity_cols Intensity column numbers
#'
#' @return Similarity value (double)
compute_intensity_similarity <- function(current_index, candidate_index,
                                         intensity_cols) {
  num_of_both_have_values <- 0
  num_of_similar_values <- 0
  kErrorRate <- 0.05

  for (intensity_col in intensity_cols) {
    val1 <- mvp_env$dt[[intensity_col]][current_index]
    val2 <- mvp_env$dt[[intensity_col]][candidate_index]

    if (!is.na(val1) && !is.na(val2)) {
      num_of_both_have_values <- num_of_both_have_values + 1

      upper_bound <- val1 * (1 + kErrorRate)
      lower_bound <- val1 * (1 - kErrorRate)

      if (lower_bound <= val2 && val2 <= upper_bound) {
        num_of_similar_values <- num_of_similar_values + 1
      }
    }
  }

  similarity <- ifelse(num_of_both_have_values == 0,
                       0, num_of_similar_values / num_of_both_have_values)
  return(similarity)
}
