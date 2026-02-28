#### ---------- FUNCTIONS FOR LACN ANALYSIS ----------- ####


#### -----------QUESTION KEY Function------------####

keyFunction <- function(question, ...) {
  key <- response_key |>
    dplyr::filter(main == question) |>
    dplyr::select(Question, ...) |>
    dplyr::distinct()

  return(key)
}


#### -----------Viz Functions------------------####

matrixPlot <- function(data, breaks = NULL, college, title = NULL, font = "Source Sans 3", size = 45) {
  tryCatch(
    {
      sysfonts::font_add_google(font)
    },
    error = function(e) {
      message("Note: Could not load font '", font, "'. Using defaults.")
      font <<- ""
    }
  )

  showtext::showtext_auto()

  if (!missing(breaks)) {
    stopifnot(length(breaks) > 1)
  }


  if (missing(breaks)) {
    seq <- c(
      0,
      ceiling(max(data["n"]) / 3),
      ceiling((2 / 3) * max(data["n"])),
      ceiling(max(data["n"]))
    )
  } else {
    seq <- breaks
  }


  plot <- ggplot2::ggplot(data = data, mapping = ggplot2::aes(reorder(`Institution Name`, n), n)) +
    ggplot2::geom_hline(
      yintercept = seq,
      colour = "grey"
    ) +
    ggplot2::scale_y_continuous(breaks = seq) +
    ggplot2::geom_bar(stat = "identity", fill = "#7CBCE8") +
    ggplot2::labs(
      title = title,
      x = NULL,
      y = "Total"
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      text = element_text(size = size, family = font)
    )


  if (!missing(college)) {
    indiv <- data |>
      dplyr::filter(`Institution Name` == college)

    return(
      plot +
        ggplot2::geom_bar(data = indiv, stat = "identity", fill = "#217DBB") +
        ggrepel::geom_text_repel(
          data = indiv,
          mapping = ggplot2::aes(label = `Institution Name`),
          nudge_y = max(data["n"]) / 2,
          nudge_x = -5,
          size = 13,
          colour = "black",
          family = "Source Sans 3"
        )
    )
  } else {
    return(plot)
  }
}

singlePlot <- function(data, q, college = NULL, title = NULL, string_rem, font = "Source Sans 3", size = 25, lineheight = 0.5, angle) {
  viz <- ggplot2::ggplot(
    data = data,
    mapping = ggplot2::aes(reorder(.data[[q]], freq), freq)
  ) +
    ggplot2::geom_hline(yintercept = seq(0, 1, by = 0.2), colour = "grey") +
    ggplot2::geom_bar(
      width = 0.6,
      stat = "identity",
      fill = "#7CBCE8"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      breaks = seq(0, 1, by = 0.2),
      labels = c("0%", "20%", "40%", "60%", "80%", "100%")
    ) +
    scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 20)) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = title,
      x = NULL,
      y = "\nFrequency"
    ) +
    ggplot2::theme(
      axis.ticks = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      text = element_text(size = size, family = font, lineheight = lineheight)
    )

  if (!missing(college)) {
    college_chr <- as.character(college)

    indiv <- question_list[[q]][
      question_list[[q]]["Institution Name"] == college_chr,
    ] |>
      dplyr::select(`Institution Name`, tidyselect::all_of(q))

    if (!missing(string_rem)) {
      suppressMessages(
        indiv[q] <- stringr::str_replace(string = tibble::deframe(indiv[q]), pattern = string_rem, replacement = "")
      )
    }

    suppressMessages(
      indiv <- indiv |>
        dplyr::left_join(data)
    )


    return(
      viz +
        geom_bar(
          data = indiv,
          width = 0.6,
          stat = "identity", fill = "#217DBB"
        ) +
        ggrepel::geom_text_repel(
          data = indiv,
          aes(label = "Your School"),
          nudge_y = 0.2,
          nudge_x = 0.5,
          color = "black",
          size = size / 4,
          angle = angle,
          family = font
        )
    )
  } else {
    return(viz)
  }
}

tableViz <- function(data, var, college = NULL, title = "Summary", subtitle = NULL, ...) {
  if (!missing(college)) {
    labels <- c("N", "Mean", "Median", "Max", "Min", college)
  } else {
    labels <- c("N", "Mean", "Median", "Max", "Min")
  }

  variable <- tibble::deframe(data[var])

  N <- as.integer(sum(!is.na(variable)))
  Mean <- mean(variable, ...)
  Median <- median(variable, ...)
  Max <- max(variable, ...)
  Min <- min(variable, ...)

  if (!missing(college)) {
    College <- data |>
      dplyr::filter(`Institution Name` == college) |>
      dplyr::pull(.data[[var]])

    if (purrr::is_empty(College)) {
      College <- 0
    }
  }


  if (!missing(college)) {
    stats <- c(N, Mean, Median, Max, Min, College)
  } else {
    stats <- c(N, Mean, Median, Max, Min)
  }


  return(
    data.frame(labels, stats) |>
      gt::gt() |>
      gt::tab_header(title = title, subtitle = subtitle) |>
      gt::cols_label(labels = "", stats = "") |>
      gt::fmt_number(
        columns = stats,
        decimals = 0
      ) |>
      gt::tab_options(
        container.width = gt::pct(75)
      )
  )
}

nTab <- function(var) {
  glue::glue("N = {as.integer(sum(!is.na(var)))}")
}


# Service/Program Table

serviceTab <- function(data, q, title = "Title", subtitle = "Subtitle", offer) {
  if (missing(offer)) {
    warning("Offer missing. Enter program, service, conference, or other.")
  }

  q_n <- question_list[[q]] |>
    dplyr::filter(dplyr::if_any(.cols = !(1:2), .fns = ~ !is.na(.x))) |>
    nrow()

  tab <- data |>
    gt::gt() |>
    gt::tab_header(
      title = title,
      subtitle = glue::glue("{subtitle} (n = {q_n})")
    ) |>
    gt::cols_label(
      value = offer,
      n = "N",
      freq = "Frequency"
    ) |>
    gt::fmt_number(
      columns = freq,
      pattern = "{x}%",
      n_sigfig = 2
    ) |>
    gt::cols_width(
      value ~ px(500)
    ) |>
    gt::cols_align(
      align = "center",
      columns = n:freq
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_fill(color = "aliceblue")
      ),
      locations = gt::cells_body(
        columns = dplyr::everything(),
        rows = as.numeric(row.names(data)) %% 2 == 0
      )
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(weight = "bold")
      ),
      locations = gt::cells_column_labels(
        columns = everything()
      )
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(style = "italic")
      ),
      locations = gt::cells_title(groups = "subtitle")
    )


  return(tab)
}

serviceCustom <- function(q, dim, college = "") {
  tbl <- question_list[[q]] |>
    pivot_longer(
      cols = !(1:2),
      names_to = "Question",
      values_to = "Your School"
    ) |>
    left_join(
      keyFunction(q, eval(dim))
    ) |>
    filter(`Institution Name` == college) |>
    select(eval(dim), `Your School`) |>
    rename(value = dim) |>
    mutate(`Your School` = case_when(
      is.na(`Your School`) ~ "",
      TRUE ~ "Yes"
    ))

  return(tbl)
}
