# Resolve repo root without Windows-absolute setwd().
# Override with PROJECT_ROOT if needed (Docker: /app).

.crime_root <- function() {
  env <- Sys.getenv("PROJECT_ROOT", unset = "")
  if (nzchar(env)) {
    return(normalizePath(env, winslash = "/", mustWork = TRUE))
  }
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(file_arg) == 1L && nzchar(file_arg[[1]])) {
    return(normalizePath(file.path(dirname(file_arg[[1]]), ".."), winslash = "/"))
  }
  wd <- normalizePath(getwd(), winslash = "/")
  if (basename(wd) == "r_scripts") {
    return(dirname(wd))
  }
  wd
}
