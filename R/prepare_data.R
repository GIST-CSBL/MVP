mvp_env <- new.env(parent = emptyenv())

#' Before applying MVP algorithm, preprocess input data such as na converting
#'
#' @param input Input file path that want to process MVP
#' @param intensity_cols Intensity column numbers
#' @param na_expressions The values that user want to convert to NA
#'
#' @return Preprocessed data frame (data.table) that can use MVP algorithm
#'
#' @import data.table
#' @export
preprocess_input_data <- function(input, key_column_indicies,
                                  intensity_cols, na_expressions) {
  dt <- data.table::fread(input)

  # Calculate information of column indices
  whole_column_indices <- 1:ncol(dt)
  non_intensity_cols <- setdiff(whole_column_indices, intensity_cols)
  # non_intensity_cols <- find_non_intensity_cols(1:ncol(dt), intensity_cols)

  # Reload original data with proper column classes
  dt <- convert_column_classes(input, whole_column_indices,
                                        key_column_indicies, intensity_cols)

  non_intensity_dt <- dt[, non_intensity_cols, with = F]
  intensity_dt <- convert_input_to_na(dt[, intensity_cols, with = F],
                                      na_expressions)

  preprocessed_dt <- dplyr::bind_cols(non_intensity_dt, intensity_dt)
  preprocessed_dt <- append_original_record_idx(preprocessed_dt)
  return(preprocessed_dt)
}

convert_column_classes <- function(file_path,
                                   whole_column_indices,
                                   key_column_indices,
                                   intensity_column_indices) {

  numeric_column_indices <- union(key_column_indices, intensity_column_indices)
  character_column_indices <- setdiff(whole_column_indices,
                                      numeric_column_indices)
  column_class_converted_dt <-
    data.table::fread(file_path,
                      colClasses = list(numeric = numeric_column_indices,
                                        character = character_column_indices))

  return(column_class_converted_dt)
}

#' Find non-intensity columns in data frame
#'
#' @param whole_cols Whole column numbers
#' @param intensity_cols Intensity column numbers
#'
#' @return Non intensity column numbers
find_non_intensity_cols <- function(whole_cols, intensity_cols) {
  setdiff(whole_cols, intensity_cols)
}

#' Convert user specified input values to NA
#'
#' @param dt Input data frame (data.table)
#' @param na_expressions The values that user want to convert to NA
#'
#' @return NA mapped data frame (data.table)
convert_input_to_na <- function(dt, na_expressions) {
  for (current_na_expression in na_expressions) {
    dt[dt == current_na_expression] <- NA
  }
  return(dt)
}

#' Append original record index (number, order)
#'
#' @param dt Input data frame (data.table)
#'
#' @return Record index appended data frame (data.table)
append_original_record_idx <- function(dt) {
  result_dt <- data.table::copy(dt)

  original_record_idx <- as.character(1:nrow(dt))
  data.table::set(result_dt, i = NULL, j = "record_idx", original_record_idx)
  return(result_dt)
}
