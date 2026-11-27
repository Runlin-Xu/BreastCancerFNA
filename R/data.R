#' Example FNA features for ten breast masses
#'
#' A ten-row subset of the Breast Cancer Wisconsin (Diagnostic) dataset with the
#' 30 cell-nucleus features used by [predict_diagnosis()], plus the sample
#' identifier. It is the same data as `inst/extdata/example_input.csv`, provided
#' as a documented dataset so that examples and checks can load it with
#' `data(example_fna)`.
#'
#' @format A data frame with 10 rows and 31 columns: `id` (sample identifier)
#'   followed by the 30 numeric features, using the original Kaggle column names
#'   (including names that contain a space, such as `concave points_mean`).
#'
#' @source \url{https://www.kaggle.com/datasets/uciml/breast-cancer-wisconsin-data}
#'
#' @examples
#' data(example_fna)
#' predict_diagnosis(example_fna)
"example_fna"
