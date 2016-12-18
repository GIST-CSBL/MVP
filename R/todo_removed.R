foo <- function(input, key_cols, key_thrshs, intensity_cols, na_expressions,
                output_path) {
  dt <- preprocess_input_data(input, intensity_cols, na_expressions)

  conformities <- c(0.3, 0.5, 0.7)
  for (conformity in conformities) {
    preprocessed <- apply_pairwise_method(dt, key_cols, key_thrshs,
                                          intensity_cols, conformity)

    output_name <- stringr::str_c(output_path, "pairwise_result_", conformity,
                                  ".tsv")
    print(output_name)
    readr::write_tsv(preprocessed, output_name)
  }

  for (conformity in conformities) {
    preprocessed <- apply_clique_method(dt, key_cols, key_thrshs,
                                          intensity_cols, conformity)

    output_name <- stringr::str_c(output_path, "clique_result_", conformity,
                                  ".tsv")
    print(output_name)
    readr::write_tsv(preprocessed, output_name)
  }
}

convert_table_to_ml_form <- function(input_path, intensity_cols, label) {
  dt <- data.table::fread(input_path) %>%
    extract_defect_free_table(intensity_cols)

  intensity_dt <- dt[, intensity_cols, with = F]
  ml_form <- data.table::data.table(t(intensity_dt))

  return(dplyr::bind_cols(ml_form, label))
}

make_class_lable_vector <- function(intensities_of_classes,
                                    labels_of_classes) {
  label_vector <- character()

  i <- 1
  for (current_class in intensities_of_classes) {
    for (j in 1:length(current_class)) {
      label_vector <- c(label_vector, labels_of_classes[i])
    }

    i <- i + 1
  }

  return(data.table::data.table(label = label_vector))
}

process_making_ml_form <- function(input_path, output_path,
                                   intensities_of_classes, labels_of_classes) {
  label <- make_class_lable_vector(intensities_of_classes, labels_of_classes)
  ml_form_dt <- convert_table_to_ml_form(input_path,
                                         unlist(intensities_of_classes), label)
  readr::write_tsv(ml_form_dt, output_path)
}
