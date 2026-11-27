read_example <- function() {
  read.csv(system.file("extdata", "example_input.csv",
                       package = "BreastCancerFNA"),
           check.names = FALSE)
}

test_that("missing columns give an informative error", {
  expect_error(predict_diagnosis(data.frame(a = 1)), "Missing")
})

test_that("threshold is applied to the probability", {
  df <- read_example()
  p  <- predict_malignancy_probability(df)
  
  for (t in c(0.19, 0.5, 0.9)) {
    expect_equal(predict_diagnosis(df, threshold = t), ifelse(p >= t, "M", "B"))
  }
})

test_that("threshold outside [0, 1] is rejected", {
  df <- read_example()
  expect_error(predict_diagnosis(df, threshold = -0.01), "between 0 and 1")
  expect_error(predict_diagnosis(df, threshold = 1.01),  "between 0 and 1")
})

test_that("example data match the documented output", {
  expect_equal(predict_diagnosis(read_example())[1:3], c("M", "B", "B"))
})

test_that("extra columns such as id are ignored", {
  df <- read_example()
  features_only <- df[, setdiff(names(df), "id")]
  expect_equal(predict_diagnosis(df), predict_diagnosis(features_only))
})
