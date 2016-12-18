handle_missing_value_strict <- function(input, intensity_col_list,
                                        na_expressions) {
  dt <- preprocess_input_data(input, unlist(intensity_col_list),
                              na_expressions)
  result_list <- process_missing_value_strict(dt, intensity_col_list)
  return(result_list)
}

process_missing_value_strict <- function(dt, intensity_col_list) {
  picking_index <- integer()
  dropping_index <- integer()
  num_of_records <- nrow(dt)

  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {
    current_record <- dt[current_index]
    intensity_part <- current_record[, unlist(intensity_col_list), with = F]

    if (!have_missing_value(intensity_part)) {
      picking_index <- c(picking_index, current_index)
    } else {
      # If intensities of specific class have all missing value,
      # then we assume MS can't record it
      recording_exception_flag <- FALSE

      for (intensity_cols in intensity_col_list) {
        current_class <- current_record[, intensity_cols, with = F]
        if (all(is.na(current_class))) {
          recording_exception_flag <- TRUE
          break
        }
      }

      if (recording_exception_flag) {
        picking_index <- c(picking_index, current_index)
      } else {
        dropping_index <- c(dropping_index, current_index)
      }

    }

    setTxtProgressBar(pb, current_index)
  }
  close(pb)

  return(list(dt[picking_index], dt[dropping_index]))
}

have_missing_value <- function(record) {
  return(any(is.na(record)))
}
