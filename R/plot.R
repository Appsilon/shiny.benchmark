#' Plot for shiny_benchmark class
#'
#' @param x shiny_benchmark object
#' @param ... Other parameters
#'
#' @return Return a `ggplot` object that compares different git refs
#'
#' @method plot shiny_benchmark
#' @import dplyr
#' @import ggplot2
#' @importFrom utils globalVariables
#' @export
plot.shiny_benchmark <- function(x, ...) {
  if (!requireNamespace(package = "ggplot2", quietly = TRUE))
    stop("ggplot2 is missing. Please, consider intalling ggplot2.")

  plot_df <- lapply(X = x$performance, FUN = bind_rows) %>%
    bind_rows(.id = "commit") %>%
    arrange(date) %>%
    mutate(commit = factor(x = commit, levels = unique(commit))) %>%
    group_by(commit, test_name) %>%
    summarise(
      min = min(duration_ms),
      mean = mean(duration_ms),
      max = max(duration_ms),
      .groups = "keep"
    ) %>%
    ungroup()

  g <- ggplot(data = plot_df, mapping = aes(x = commit, y = mean)) +
    geom_pointrange(mapping = aes(ymin = min, ymax = max)) +
    facet_wrap(~test_name) +
    ylab("Duration (ms)") +
    xlab("Commit") +
    theme_bw()

  return(g)
}
