#' Make simulation data using various parameter
#'
#' @param intensity_cols Intensity column numbers
#' @param maximum_duplicate Maximum possible duplicate number
#' @param noise_sd Normal distribution standard deviation parameter
#' @param missing_rates Missing rates sequence. e.g) c(0.1, 0.2, 0.3)
#' @param defect_free_dt Defect free data frame (data.table)
#'
#' @return Simulation data frame (data.table)
#' @import magrittr
construct_simulation_data <- function(defect_free_dt,
                                      intensity_cols,
                                      maximum_duplicate = 20,
                                      noise_sd = 4,
                                      missing_rates = seq(0.0, 0.9, by = 0.1)) {
  simulation_dt <-
    append_original_record_idx(defect_free_dt) %>%
    make_record_duplicated_table(maximum_duplicate) %>%
    add_random_noise(intensity_cols, noise_sd) %>%
    make_random_missing_value(intensity_cols, missing_rates)

  return(simulation_dt)
}

#' Extract all records don't have any missing value (Defect free records)
#'
#' @param dt Input data frame (data.table)
#' @param intensity_cols Intensity column numbers
#'
#' @return Data frame (data.table) consist of defect free records
extract_defect_free_table <- function(dt, intensity_cols) {
  num_of_records <- nrow(dt)
  intensity_dt <- dt[, intensity_cols, with = F]
  extracting_index <- integer()

  print("Start extracting defect-free data table...")
  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {
    has_na <- any(is.na(intensity_dt[current_index]))
    if (!has_na) {
      extracting_index <- c(extracting_index, current_index)
    }

    setTxtProgressBar(pb, current_index)
  }
  close(pb)

  return(dt[extracting_index])
}

#' To simulate real world data, make record duplicated data frame (data.table)
#' To test various situation, user can adjust maximum duplicate number
#'
#' @param dt Input data frame (data.table)
#' @param maximum_duplicate Maximum possible duplicate number
#'
#' @return Record duplicated data frame
make_record_duplicated_table <- function(dt, maximum_duplicate) {
  record_duplicated_dt <- NULL
  num_of_records <- nrow(dt)

  print("Start record duplicating...")
  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {
    num_of_duplicates <- sample(x = 1:maximum_duplicate, size = 1)

    for (duplicate in 1:num_of_duplicates) {
      index_manipulated_record <- manipulate_table_index(dt[current_index],
                                                         duplicate,
                                                         num_of_duplicates)
      l <- list(record_duplicated_dt, index_manipulated_record)
      record_duplicated_dt <- data.table::rbindlist(l)
    }
    setTxtProgressBar(pb, current_index)
  }
  close(pb)
  return(record_duplicated_dt)
}

#' Before testing simulation restoration rate, we need to manipulated record
#' index. manipuliate_table_index can handle this procedure.
#'
#' @param record Current record
#' @param current_number Current duplicate number (1 to maximum_number)
#' @param maximum_number Maximum duplicate number
#'
#' @return Table index manipulated record
manipulate_table_index <- function(record, current_number, maximum_number) {
  index_col_number <- ncol(record)
  original_index <- record[[index_col_number]][1]
  manipulated_index <- stringr::str_c(original_index, current_number,
                                      maximum_number, sep = "-")
  data.table::set(record, i = 1L, j = index_col_number, manipulated_index)
  return(record)
}

#' Add random noise (normally distributed) to each intensity element
#'
#' @param dt Input data frame (data.table)
#' @param intensity_cols Intensity column numbers
#' @param noise_sd Normal distribution standard deviation parameter
#'
#' @return Noise added data frame (data.table)
#' @importFrom stats rnorm
add_random_noise <- function(dt, intensity_cols, noise_sd) {
  noise_added_dt <- data.table::copy(dt)
  num_of_records <- nrow(dt)
  num_of_intensity_cols <- length(intensity_cols)

  print("Start adding random noise...")
  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {

    for (intensity_col in intensity_cols) {
      noise <- rnorm(1, mean = 0, sd = noise_sd) / 100.0
      original_value <- noise_added_dt[[intensity_col]][current_index]
      error <- original_value * noise

      data.table::set(noise_added_dt, current_index, intensity_col,
                      original_value + error)
    }

    setTxtProgressBar(pb, current_index)
  }
  close(pb)
  return(noise_added_dt)
}

#' Make random missing value to intensity element
#'
#' @param dt Input data frame (data.table)
#' @param intensity_cols Intensity column numbers
#' @param missing_rates Missing rates sequence. e.g) c(0.1, 0.2, 0.3)
#'
#' @return Randomly missing value made data frame
make_random_missing_value <- function(dt, intensity_cols, missing_rates) {
  num_of_records <- nrow(dt)
  num_of_intensity_cols <- length(intensity_cols)

  print("Start making random missing values...")
  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  for (current_index in 1:num_of_records) {
    missing_rate <- sample(x = missing_rates, size = 1)

    if (missing_rate == 0.0) {
      next
    }

    num_of_missing_value <- round(num_of_intensity_cols * missing_rate)
    missing_value_mapped_column <- sample(intensity_cols, num_of_missing_value)

    data.table::set(dt, i = current_index, j = missing_value_mapped_column, NA)
    setTxtProgressBar(pb, current_index)
  }
  close(pb)
  return(dt)
}
