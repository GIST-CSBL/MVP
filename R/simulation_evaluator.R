evaluate_simulation_result <- function(input, key_cols, key_thrshs,
                                       intensity_cols, conformity_thrsh,
                                       na_expression, num_of_simulation = 30,
                                       max_duplicate, noise_sd, missing_start,
                                       missing_end) {

  accuracy_vector <- numeric()
  original_dt <- preprocess_input_data(input, intensity_cols, na_expression)
  defect_free_dt <- extract_defect_free_table(original_dt, intensity_cols)
  for (current_simulation in 1:num_of_simulation) {
    simulation_dt <-
      construct_simulation_data(defect_free_dt,
                                intensity_cols,
                                maximum_duplicate = max_duplicate,
                                noise_sd = noise_sd,
                                missing_rates = seq(missing_start, missing_end, by = 0.1))
    preprocessed_dt <- apply_pairwise_method(simulation_dt, key_cols,
                                             key_thrshs,
                                             intensity_cols, conformity_thrsh)
    # preprocessed_dt <- apply_clique_method(simulation_dt, key_cols,
    #                                        key_thrshs,
    #                                        intensity_cols, conformity_thrsh)
    accuracy_result <- compute_restoration_rate(preprocessed_dt)
    print(accuracy_result)
    accuracy_vector <- c(accuracy_vector, accuracy_result)
  }
  return(accuracy_vector)
}

compute_restoration_rate <- function(dt) {
  num_of_records <- nrow(dt)
  index_column_number <- ncol(dt)

  record_index_vector <- character()
  num_of_perfect_restoration <- 0

  for (i in 1:num_of_records) {
    current.idx <- dt[[index_column_number]][i]

    idx.vector <- stringr::str_split(current.idx, ":")[[1]]

    first <- character()
    second <- character()
    third <- character()

    for (chunk in idx.vector) {
      splitted <- stringr::str_split(chunk, "-")[[1]]
      first <- c(first, splitted[1])
      second <- c(second, splitted[2])
      third <- c(third, splitted[3])
    }

    idx.dt <- data.table(first, second, third)

    # check unique first term
    for (term in unique(idx.dt[[1]])) {
      filtered <- dplyr::filter(idx.dt, first == term)
      maximum.records <- filtered[[3]][1]

      if (nrow(filtered) == maximum.records) {
        num_of_perfect_restoration <- num_of_perfect_restoration + 1
      }

      record_index_vector <- c(record_index_vector, term)
    }

  }

  # unique 처리
  record_index_vector <- unique(record_index_vector)

  return(num_of_perfect_restoration / length(record_index_vector))
}

simulate_using_various_parameters <- function(input, key_cols, key_thrshs,
                                              intensity_cols,
                                              na_expression, num_of_simulation = 30,
                                              output_path) {
  path <- stringr::str_c("~/NAS/public/Data/[Geunho-2016-08-24]",
                         "MVP_Processed_Data/simulation_parameter.txt")
  parameter_dt <- data.table::fread(path)

  accuracy_list <- numeric()
  sem_list <- numeric()

  for (current_parameters in 1:nrow(parameter_dt)) {
    print(parameter_dt[current_parameters])
    max_duplicate <- parameter_dt[['MaxDuplicate']][current_parameters]
    missing_rate_start <- parameter_dt[['MissingRateStart']][current_parameters]
    missing_rate_end <- parameter_dt[['MissingRateEnd']][current_parameters]
    noise <- parameter_dt[['Noise']][current_parameters]
    conformity <- parameter_dt[['Conformity']][current_parameters]

    accuracy_vec <- evaluate_simulation_result(input, key_cols, key_thrshs,
                                               intensity_cols, conformity,
                                               na_expression, num_of_simulation,
                                               max_duplicate, noise,
                                               missing_rate_start, missing_rate_end)

    print(mean(accuracy_vec))
    accuracy_list <- c(accuracy_list, mean(accuracy_vec))
    sem_list <- c(sem_list, sd(accuracy_vec) / sqrt(length(accuracy_vec)))
  }

  accuracy_dt <- data.table::data.table(accuracy_list)
  sem_dt <- data.table::data.table(sem_list)

  result_dt <- dplyr::bind_cols(parameter_dt, accuracy_dt, sem_dt)
  readr::write_tsv(result_dt, output_path)
}
