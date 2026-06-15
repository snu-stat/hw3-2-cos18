local({
  quarto_pandoc_dir <- "/Applications/quarto/bin/tools/aarch64"

  if (!dir.exists(quarto_pandoc_dir)) {
    return(invisible(NULL))
  }

  path_sep <- .Platform$path.sep
  current_path <- Sys.getenv("PATH", unset = "")
  path_parts <- strsplit(current_path, path_sep, fixed = TRUE)[[1]]

  if (!(quarto_pandoc_dir %in% path_parts)) {
    Sys.setenv(
      PATH = paste(c(quarto_pandoc_dir, current_path), collapse = path_sep)
    )
  }
})
