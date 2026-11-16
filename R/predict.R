# Read the files of the fitted model that are stored in inst/extdata.
# Internal helper, not exported.
load_model_files <- function() {
  extdata_file <- function(file_name) {
    system.file("extdata", file_name, package = "BreastCancerFNA", mustWork = TRUE)
  }
  list(
    model = readRDS(extdata_file("final_mlp_model.rds")),
    scaler = readRDS(extdata_file("final_mlp_scaler.rds")),
    feature_names = readRDS(extdata_file("final_mlp_feature_names.rds")),
    threshold = utils::read.csv(extdata_file("final_mlp_settings.csv"))$classification_threshold
  )
}

#' Predict the probability that a breast mass is malignant
#'
#' @description
#' Computes, for every row of \code{feature_df}, the probability that the breast
#' mass is malignant. The 30 features are first standardised with the means and
#' standard deviations of the 569 training samples, and then passed to the fitted
#' multilayer perceptron (MLP, \code{nnet} with 5 hidden units and weight decay
#' 0.001). This is the same calculation as in the project's Shiny app.
#'
#' @param feature_df A \code{data.frame} with one row per sample and the 30
#'   numeric feature columns of the Breast Cancer Wisconsin (Diagnostic) Data Set,
#'   named exactly as in the original data (for example \code{radius_mean},
#'   \code{concave points_worst}). Extra columns such as \code{id} are ignored.
#'   When reading a CSV file, use \code{check.names = FALSE} so that the column
#'   names containing a space are kept.
#'
#' @return A numeric vector of probabilities between 0 and 1, one value per row
#'   of \code{feature_df}. Rows with missing feature values give \code{NA}.
#'
#' @examples
#' example_df <- read.csv(
#'   system.file("extdata", "example_input.csv", package = "BreastCancerFNA"),
#'   check.names = FALSE
#' )
#' predict_malignancy_probability(example_df)
#'
#' @seealso \code{\link{predict_diagnosis}} for class labels.
#' @import nnet
#' @importFrom stats predict
#' @export
predict_malignancy_probability <- function(feature_df) {
  if (!is.data.frame(feature_df)) {
    stop("feature_df must be a data.frame.")
  }
  model_files <- load_model_files()
  feature_names <- model_files$feature_names

  missing_columns <- setdiff(feature_names, names(feature_df))
  if (length(missing_columns) > 0) {
    stop("Missing feature columns: ", paste(missing_columns, collapse = ", "))
  }

  # Build a numeric matrix with the columns in the order used for training.
  feature_matrix <- sapply(feature_names, function(f) as.numeric(feature_df[[f]]))
  feature_matrix <- matrix(feature_matrix, ncol = length(feature_names),
                           dimnames = list(NULL, feature_names))

  # Standardise with the training means and standard deviations.
  scaled_matrix <- sweep(feature_matrix, 2, model_files$scaler$means, "-")
  scaled_matrix <- sweep(scaled_matrix, 2, model_files$scaler$standard_deviations, "/")

  as.numeric(predict(model_files$model, newdata = scaled_matrix, type = "raw"))
}

#' Predict whether a breast mass is malignant or benign
#'
#' @description
#' Classifies every row of \code{feature_df} as malignant (\code{"M"}) or benign
#' (\code{"B"}). The malignancy probability from
#' \code{\link{predict_malignancy_probability}} is compared with a decision
#' threshold: a sample is labelled \code{"M"} when its probability is at least
#' the threshold. The default threshold, 0.19, was chosen by maximising the F2
#' score (recall weighted twice as much as precision) in cross-validation,
#' because missing a malignant mass is more costly than a false alarm.
#'
#' The model is for teaching and research only and is not a clinically
#' validated diagnostic tool.
#'
#' @param feature_df A \code{data.frame} with the 30 numeric feature columns of
#'   the Breast Cancer Wisconsin (Diagnostic) Data Set (see
#'   \code{\link{predict_malignancy_probability}}). Extra columns are ignored.
#' @param threshold Probability cut-off between 0 and 1. \code{NULL} (default)
#'   uses the threshold stored with the model (0.19).
#'
#' @return A character vector of predicted class labels, \code{"M"} (malignant)
#'   or \code{"B"} (benign), one per row of \code{feature_df}.
#'
#' @examples
#' example_df <- read.csv(
#'   system.file("extdata", "example_input.csv", package = "BreastCancerFNA"),
#'   check.names = FALSE
#' )
#' predict_diagnosis(example_df)
#'
#' # A stricter cut-off gives fewer malignant labels
#' predict_diagnosis(example_df, threshold = 0.5)
#'
#' @export
predict_diagnosis <- function(feature_df, threshold = NULL) {
  if (is.null(threshold)) {
    threshold <- load_model_files()$threshold
  }
  if (!is.numeric(threshold) || length(threshold) != 1 || threshold < 0 || threshold > 1) {
    stop("threshold must be a single number between 0 and 1.")
  }
  probability <- predict_malignancy_probability(feature_df)
  ifelse(probability >= threshold, "M", "B")
}
