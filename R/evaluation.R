#' Calculate Precision, Recall, F1
#' 
#' Calculate extraction performance metrics
#' 
#' @param predicted Vector of predicted extractions
#' @param ground_truth Vector of ground truth extractions
#' @return List with precision, recall, and f1 scores
calculate_metrics <- function(predicted, ground_truth) {
  # Convert to sets for comparison
  pred_set <- unique(unlist(predicted))
  truth_set <- unique(unlist(ground_truth))
  
  tp <- length(intersect(pred_set, truth_set))
  fp <- length(setdiff(pred_set, truth_set))
  fn <- length(setdiff(truth_set, pred_set))
  
  precision <- if (tp + fp == 0) 0 else tp / (tp + fp)
  recall <- if (tp + fn == 0) 0 else tp / (tp + fn)
  f1 <- if (precision + recall == 0) 0 else 2 * (precision * recall) / (precision + recall)
  
  list(
    precision = precision,
    recall = recall,
    f1 = f1,
    tp = tp,
    fp = fp,
    fn = fn
  )
}

#' Compare Extraction Methods
#' 
#' Compare performance of different extraction methods
#' 
#' @param results_list Named list of extraction results
#' @param ground_truth Ground truth data
#' @return Comparison tibble
compare_methods <- function(results_list, ground_truth) {
  comparison <- purrr::map_dfr(names(results_list), function(method_name) {
    metrics <- calculate_metrics(results_list[[method_name]], ground_truth)
    tibble::tibble(
      method = method_name,
      precision = metrics$precision,
      recall = metrics$recall,
      f1 = metrics$f1
    )
  })
  
  comparison
}

#' Plot Performance Comparison
#' 
#' Create visualization of extraction method performance
#' 
#' @param comparison_data Output from compare_methods()
#' @return ggplot object
plot_performance <- function(comparison_data) {
  comparison_data %>%
    tidyr::pivot_longer(cols = c(precision, recall, f1), 
                       names_to = "metric", 
                       values_to = "value") %>%
    ggplot2::ggplot(ggplot2::aes(x = method, y = value, fill = metric)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      title = "Extraction Method Performance Comparison",
      x = "Method",
      y = "Score",
      fill = "Metric"
    ) +
    ggplot2::theme_minimal()
}