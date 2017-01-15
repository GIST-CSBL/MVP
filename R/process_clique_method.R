# mvp_env <- new.env(parent = emptyenv())

#' Apply clique method to handle dirty data such as duplicate record
#' and missing value problem
#'
#' @param dt Input data frame (data.table)
#' @param key_cols Key (m/z, RT ...) column numbers
#' @param key_thrsh Key (m/z, RT ...) column threshold with same order key_cols
#' @param intensity_cols Intensity column numbers
#' @param conformity_thrsh Conformity threshold
#'
#' @return Dirty data-free data frame (data.table)
apply_clique_method <- function(dt, key_cols, key_thrsh, intensity_cols,
                                conformity_thrsh) {
  before_processed_dt <- dt
  after_processed_dt <- NULL

  iteration <- 1
  while (TRUE) {
    print(stringr::str_c("Start Iteration ", iteration))
    before_processed_dt <- arrange_data_using_key(before_processed_dt, key_cols)
    after_processed_dt <- process_clique_merge(before_processed_dt, key_cols,
                                               key_thrsh, intensity_cols,
                                               conformity_thrsh)

    print(stringr::str_c("# of records (Before): ",
                         nrow(before_processed_dt),
                         " -> # of records (After): ",
                         nrow(after_processed_dt)))

    if (nrow(before_processed_dt) == nrow(after_processed_dt)) {
      break
    } else {
      before_processed_dt <- after_processed_dt
    }

    # # todo remove
    # if (iteration == 1) {
    #   break
    # }

    iteration <- iteration + 1
  }
  return(after_processed_dt)
}

process_clique_merge <- function(dt, key_cols, key_thrsh, intensity_cols,
                                 conformity_thrsh) {
  num_of_records <- nrow(dt)
  mvp_env$dt <- data.table::copy(dt)
  mvp_env$already_used <- logical(num_of_records)
  final_extracting_indexes <- integer()

  pb <- txtProgressBar(max = num_of_records, width = 70, style = 3)
  pb_index <- 1
  for (current_index in 1:num_of_records) {
    setTxtProgressBar(pb, pb_index)
    pb_index <- pb_index + 1
    if (mvp_env$already_used[current_index]) {
      next
    }

    if (current_index == num_of_records) {
      mvp_env$already_used[current_index] <- T
      final_extracting_indexes <- c(final_extracting_indexes, current_index)
      break
    }

    indexes_of_group <- extract_duplicate_candidate(current_index, key_cols,
                                                     key_thrsh)
    #
    extracted_group <- indexes_of_group
    #

    indexes_of_group <- c(current_index, indexes_of_group)

    if (length(indexes_of_group) == 1) {
      final_extracting_indexes <- c(final_extracting_indexes, indexes_of_group)
      mvp_env$already_used[indexes_of_group] <- T
      next
    }

    # if (length(indexes_of_group) > 12) {
    #   print("Change pairwise method")
    #   print(length(indexes_of_group))
    #   best_matching_idx <- find_best_similar_record(current_index, extracted_group,
    #                                                 intensity_cols, conformity_thrsh)
    #
    #   if (is.null(best_matching_idx)) {
    #     mvp_env$already_used[current_index] <- T
    #   } else {
    #     mvp_env$already_used[c(current_index, best_matching_idx)] <- T
    #     merge_pairwise_record(current_index, best_matching_idx, intensity_cols)
    #   }
    #
    #   final_extracting_indexes <- c(final_extracting_indexes, current_index)
    #   next
    # }

    similarity_dt <- compute_all_pairwise_similarity(indexes_of_group,
                                                     intensity_cols)
    over_conformity_dt <- filter_similar_vertex_pair(similarity_dt,
                                                     conformity_thrsh)

    if (nrow(over_conformity_dt) > 50) {
      # print("Change pairwise method")
      # print(nrow(over_conformity_dt))
      best_matching_idx <- find_best_similar_record(current_index, extracted_group,
                                                    intensity_cols, conformity_thrsh)

      if (is.null(best_matching_idx)) {
        mvp_env$already_used[current_index] <- T
      } else {
        mvp_env$already_used[c(current_index, best_matching_idx)] <- T
        merge_pairwise_record(current_index, best_matching_idx, intensity_cols)
      }

      final_extracting_indexes <- c(final_extracting_indexes, current_index)
      next
    }

    cliques <- find_all_cliques(over_conformity_dt)
    clique_similarity_dt <- make_clique_similarity_table(similarity_dt, cliques)

    if (nrow(clique_similarity_dt) == 0) {
      final_extracting_indexes <- c(final_extracting_indexes, indexes_of_group)
      mvp_env$already_used[indexes_of_group] <- T
      next
    }

    ##################################
    used_vertex <- NULL
    for (clique_index in 1:nrow(clique_similarity_dt)) {
      clique_component <-
        stringr::str_split(clique_similarity_dt[['clique']][clique_index], ":")[[1]]

      clique_component <- as.integer(clique_component)

      if (any(clique_component %in% used_vertex)) {
        next
      } else {
        selecting_index <- merge_records_of_clique(clique_component,
                                                   intensity_cols)
        final_extracting_indexes <- c(final_extracting_indexes, selecting_index)
        used_vertex <- c(used_vertex, clique_component)
      }
    }

    remainder <- setdiff(indexes_of_group, used_vertex)
    final_extracting_indexes <- c(final_extracting_indexes, remainder)
    ##################################

    mvp_env$already_used[indexes_of_group] <- T
  }
  close(pb)

  return(mvp_env$dt[final_extracting_indexes])
}

compute_all_pairwise_similarity <- function(record_indexes_of_group,
                                            intensity_cols) {
  vertex1 <- integer()
  vertex2 <- integer()
  similarity_of_vertices <- numeric()
  num_of_indexes <- length(record_indexes_of_group)
  for (i in 1:(num_of_indexes - 1)) {
    for (j in (i + 1):num_of_indexes) {
      vertex1_index <- record_indexes_of_group[i]
      vertex2_index <- record_indexes_of_group[j]

      similarity <- compute_intensity_similarity(vertex1_index, vertex2_index,
                                                 intensity_cols)

      vertex1 <- c(vertex1, vertex1_index)
      vertex2 <- c(vertex2, vertex2_index)
      similarity_of_vertices <- c(similarity_of_vertices, similarity)
    }
  }

  similarity_dt <- data.table::data.table(vertex1 = vertex1,
                                          vertex2 = vertex2,
                                          similarity = similarity_of_vertices)
  return(similarity_dt)
}

filter_similar_vertex_pair <- function(similarity_dt, conformity_thrsh) {
  return(dplyr::filter(similarity_dt, similarity >= conformity_thrsh))
}

find_all_cliques <- function(similarity_dt) {
  dt <- dplyr::select(similarity_dt, vertex1, vertex2)
  graph_built_in_similarity <- igraph::graph_from_data_frame(dt,
                                                             directed = FALSE)
  cliques <- igraph::cliques(graph_built_in_similarity, min = 2)
  return(rev(cliques))
}

make_clique_similarity_table <- function(similarity_dt, cliques) {
  clique_components <- character()
  clique_similarities <- numeric()
  num_of_components <- integer()

  for (clique in cliques) {
    clique_component <- names(clique)

    clique_similarity <- compute_clique_similarity(similarity_dt,
                                                   clique_component)

    clique_component_string <- paste(clique_component, collapse = ":")
    clique_components <- c(clique_components, clique_component_string)
    clique_similarities <- c(clique_similarities, clique_similarity)
    num_of_components <- c(num_of_components, length(clique_component))
  }

  clique_similarity_table <-
    data.table::data.table(clique = clique_components,
                           similarity = clique_similarities,
                           num_of_components = num_of_components)

  return(dplyr::arrange(clique_similarity_table, desc(num_of_components),
                        desc(similarity)))
}

compute_clique_similarity <- function(similarity_dt, clique_component) {
  sorted_clique_component <- sort(clique_component, decreasing = FALSE)
  num_of_components <- length(sorted_clique_component)

  clique_similarity <- 0.0
  num_of_edges <- 0
  for (i in 1:(num_of_components - 1)) {
    for (j in (i + 1):num_of_components) {
      current_vertex_pair <- dplyr::filter(similarity_dt,
                                           vertex1 == clique_component[i],
                                           vertex2 == clique_component[j])

      clique_similarity <- clique_similarity + current_vertex_pair$similarity
      num_of_edges <- num_of_edges + 1
    }
  }

  clique_similarity <- clique_similarity / num_of_edges
  return(clique_similarity)
}

#' Title
#'
#' @param record_indexes_of_clique Integer record indexes of clique
#'                                 e.g. c(3123, 3127, 3130, 3133)
#' @param intensity_cols Intensity columns
#'
#' @return Final index which should be selected
merge_records_of_clique <- function(record_indexes_of_clique, intensity_cols) {
  total_cols <- 1:ncol(mvp_env$dt)
  non_intensity_cols <- find_non_intensity_cols(total_cols, intensity_cols)
  criterion_index <- min(record_indexes_of_clique)

  # Treat non intensity columns
  for (non_intensity_col in non_intensity_cols) {
    current_col <- mvp_env$dt[[non_intensity_col]]
    merged_value <- NULL
    if (is.character(mvp_env$dt[[non_intensity_col]])) {
      merged_value <- stringr::str_c(current_col[record_indexes_of_clique],
                                     collapse = ":")
    } else {
      merged_value <- max(current_col[record_indexes_of_clique], na.rm = TRUE)
    }

    data.table::set(mvp_env$dt, i = criterion_index, j = non_intensity_col,
                    merged_value)
  }

  # Treat intensity columns
  for (intensity_col in intensity_cols) {
    if (!check_all_missing_value(intensity_col, record_indexes_of_clique)) {
      merged_value <-
        max(mvp_env$dt[[intensity_col]][record_indexes_of_clique],
            na.rm = TRUE)
      data.table::set(mvp_env$dt, i = criterion_index, j = intensity_col,
                      merged_value)
    }
  }

  return(criterion_index)
}

check_all_missing_value <- function(intensity_col, record_indexes) {
  return(all(is.na(mvp_env$dt[[intensity_col]][record_indexes])))
}

# test_apply_clique_method <- function(input, key_cols, intensity_cols,
#                                      na_expression) {
#   input <- "~/NAS/users/ghlee/2016/MVP_Ver160718/data/KIST_Positive.tsv"
#   dt <- preprocess_input_data(input, intensity_cols, na_expression)
#   dt <- arrange_data_using_key(dt, key_cols)
#
#   mvp_env$dt <- data.table::copy(dt)
#   mvp_env$already_used <- logical(nrow(dt))
# }
