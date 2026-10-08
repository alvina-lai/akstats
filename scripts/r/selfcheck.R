# selfcheck.R — compares your results with independently recomputed answers.
# Load it with source("selfcheck.R").
check <- function(label, yours, expected, tol = 0.01, hint = NULL) {
  y <- unname(unlist(yours))
  e <- unname(unlist(expected))
  ok <- if (is.numeric(y) && is.numeric(e)) {
    length(y) == length(e) &&
      all((is.na(y) & is.na(e)) | abs(y - e) <= tol * (1 + abs(e)))
  } else {
    # Text (or mixed) results must match exactly.
    identical(as.character(y), as.character(e))
  }
  ok <- isTRUE(ok)
  cat(if (ok) "✓ " else "✗ ", label, "\n", sep = "")
  if (!ok) {
    cat("    yours:   ", format(y, digits = 4), "\n")
    cat("    expected:", format(e, digits = 4), "\n")
    if (!is.null(hint)) cat("    hint:", hint, "\n")
  }
  invisible(ok)
}
