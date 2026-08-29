# utils_pdf_text.R -----------------------------------------------------------
# A minimal PDF text extractor, in base R.
#
# WHY THIS EXISTS. Kansas publishes its Year 1 awardees as PDFs on KDHE's
# document centre, and the cloud session has no `pdftotext`, no `pdftools`, no
# `pypdf` and no route to PyPI (session 8 met this with Delaware's budget
# narrative and solved it by hand, uncommitted). A parse nobody can re-run is
# not a parse: §7.1's posture is that a figure is PARSED FROM A COMMITTED
# ARCHIVE, never transcribed, and that requires the parser to be in the repo.
#
# WHY IT DECODES THROUGH /ToUnicode AND NOT BY GUESSING. The obvious cheap
# approach is to inflate the content streams, read the Tj/TJ operands, and hope
# they are ASCII. On KDHE's files they are not: the fonts are subsetted and the
# glyph codes come out as ASCII shifted by 29, so "and" reads as "D Q G". A
# constant-offset guess would decode this document and silently mangle the next
# one, and it would mangle it into text that still looks like words.
#
# So the mapping is read out of the document: every font carries a /ToUnicode
# CMap, and this reads each page's fonts, parses their bfchar/bfrange tables,
# and decodes each string through the font that was current when it was drawn.
# When a font has no CMap the bytes are taken as Latin-1, which is what a
# non-subsetted font means.
#
# WHAT IT DOES NOT DO. No layout: it emits one line per text-positioning
# operator, in content order, which is what a bulleted award list needs and is
# not enough to reconstruct a multi-column table. No encryption, no object
# streams for page content, no CID fonts without a CMap. A caller that needs
# more than a list of lines should not reach for this.

#' Bytes to a Latin-1 string, NUL-safe
#'
#' `rawToChar()` refuses an embedded NUL, and a PDF dictionary can carry one.
#' NULs are structurally meaningless in the ASCII regions this reads (object
#' headers, dictionaries, CMaps), so they are dropped there -- and the content
#' scanner below never calls this, because in a two-byte glyph code a NUL is
#' the high byte and carries meaning.
rhtp_pdf_chr <- function(r) {
  # Declared latin1, not left unmarked: a PDF's binary regions are not UTF-8,
  # and an unmarked string sends every downstream perl regex into an "invalid
  # UTF-8" warning on the first font programme it meets.
  out <- rawToChar(r[r != as.raw(0)])
  Encoding(out) <- "latin1"
  out
}


#' Split a PDF into its numbered objects
#'
#' @return A named list, `body` per object number, as raw vectors.
rhtp_pdf_objects <- function(bytes) {
  hits <- grepRaw("obj", bytes, all = TRUE)
  ends <- grepRaw("endobj", bytes, all = TRUE)

  out <- list()
  for (h in hits) {
    # Walk back over "  N G " to the object number.
    j <- h - 1L
    while (j > 0L && bytes[j] %in% as.raw(c(32, 13, 10, 9))) j <- j - 1L
    k <- j
    while (k > 0L && bytes[k] %in% as.raw(48:57)) k <- k - 1L
    if (k == j) next                                   # no generation digits
    j <- k
    while (j > 0L && bytes[j] %in% as.raw(c(32, 13, 10, 9))) j <- j - 1L
    k2 <- j
    while (k2 > 0L && bytes[k2] %in% as.raw(48:57)) k2 <- k2 - 1L
    if (k2 == j) next                                  # no object number
    num <- suppressWarnings(as.integer(rhtp_pdf_chr(bytes[(k2 + 1L):j])))
    if (is.na(num)) next

    e <- ends[ends > h + 2L][1]
    if (is.na(e)) e <- length(bytes)
    out[[as.character(num)]] <- bytes[(h + 3L):(e - 1L)]
  }
  out
}


#' The (possibly inflated) stream inside an object body
rhtp_pdf_stream <- function(body) {
  s <- grepRaw("stream", body, all = FALSE)
  if (length(s) == 0L) return(NULL)

  header <- rhtp_pdf_chr(body[1:min(s + 6L, length(body))])
  b <- s + 6L
  while (b <= length(body) && body[b] %in% as.raw(c(13, 10))) b <- b + 1L

  e <- grepRaw("endstream", body, all = TRUE)
  e <- e[e > b][1]
  if (is.na(e)) e <- length(body) + 1L
  blob <- body[b:(e - 1L)]

  if (grepl("/FlateDecode", header, fixed = TRUE, useBytes = TRUE)) {
    return(tryCatch(memDecompress(blob, "gzip"), error = function(err) NULL))
  }
  blob
}


#' Parse a /ToUnicode CMap into a code -> string lookup
#'
#' @return A named character vector, names are decimal codes.
rhtp_pdf_tounicode <- function(cmap_raw) {
  if (is.null(cmap_raw)) return(character())
  txt <- rhtp_pdf_chr(cmap_raw)

  codes <- character()
  vals  <- character()

  hex_to_str <- function(h) {
    if (nchar(h) < 4) return("")
    idx <- seq(1, nchar(h) - 3, by = 4)
    paste(vapply(idx, function(i)
      intToUtf8(strtoi(substr(h, i, i + 3), 16L)), character(1)), collapse = "")
  }

  for (blk in regmatches(txt, gregexpr("beginbfchar[\\s\\S]*?endbfchar", txt,
                                       perl = TRUE))[[1]]) {
    m <- regmatches(blk, gregexpr("<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>", blk,
                                  perl = TRUE))[[1]]
    for (pair in m) {
      p <- regmatches(pair, regexec("<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>",
                                    pair))[[1]]
      codes <- c(codes, as.character(strtoi(p[2], 16L)))
      vals  <- c(vals, hex_to_str(p[3]))
    }
  }

  for (blk in regmatches(txt, gregexpr("beginbfrange[\\s\\S]*?endbfrange", txt,
                                       perl = TRUE))[[1]]) {
    m <- regmatches(blk, gregexpr(
      "<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>", blk,
      perl = TRUE))[[1]]
    for (trip in m) {
      p <- regmatches(trip, regexec(
        "<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>", trip))[[1]]
      lo <- strtoi(p[2], 16L); hi <- strtoi(p[3], 16L); dst <- strtoi(p[4], 16L)
      if (is.na(lo) || is.na(hi) || hi < lo || hi - lo > 65535L) next
      for (k in lo:hi) {
        codes <- c(codes, as.character(k))
        vals  <- c(vals, intToUtf8(dst + k - lo))
      }
    }
  }

  stats::setNames(vals, codes)
}


#' Decode a string operand through the current font
rhtp_pdf_decode <- function(codes, cmap, two_byte) {
  if (length(codes) == 0L) return("")
  codes <- codes[!is.na(codes)]
  if (length(codes) == 0L) return("")

  if (length(cmap) == 0L) {
    keep <- codes >= 32L & codes < 256L
    return(paste(vapply(codes[keep], intToUtf8, character(1)), collapse = ""))
  }
  if (isTRUE(two_byte)) {
    if (length(codes) < 2L) return("")
    idx <- seq(1L, length(codes) - 1L, by = 2L)
    codes <- codes[idx] * 256L + codes[idx + 1L]
  }
  out <- unname(cmap[as.character(codes)])
  paste(ifelse(is.na(out), "", out), collapse = "")
}


#' Scan one content stream and emit its text, one line per positioning operator
#'
#' Operates on integer byte codes rather than a string: in a two-byte glyph
#' code the high byte is very often NUL, and `rawToChar()` cannot hold one.
rhtp_pdf_content_lines <- function(stream, fonts) {
  b <- as.integer(stream)
  n <- length(b)
  if (n == 0L) return(character())

  lines   <- character()
  buf     <- character()
  # Strings are held here until a Tj/TJ actually paints them. A PDF also
  # carries strings that are never drawn -- /ActualText and /Alt inside
  # marked-content property lists -- and appending those straight to the line
  # buffer sprinkles stray glyphs through the output.
  pending <- character()
  cmap  <- character()
  two   <- FALSE
  i     <- 1L

  is_ws  <- function(x) x %in% c(32L, 13L, 10L, 9L, 12L, 0L)
  is_dlm <- function(x) x %in% c(40L, 41L, 60L, 62L, 91L, 93L, 47L, 37L,
                                 123L, 125L)

  flush <- function() {
    if (length(buf)) {
      lines <<- c(lines, paste(buf, collapse = ""))
      buf <<- character()
    }
  }

  while (i <= n) {
    ch <- b[i]

    if (ch == 40L) {                                    # ( literal string )
      i <- i + 1L
      depth <- 1L
      codes <- integer(0)
      while (i <= n) {
        c2 <- b[i]
        if (c2 == 92L && i < n) {                       # backslash escape
          nx <- b[i + 1L]
          esc <- c(n = 10L, r = 13L, t = 9L, b = 8L, f = 12L)
          key <- if (nx < 128L) intToUtf8(nx) else ""
          if (key %in% names(esc)) {
            codes <- c(codes, esc[[key]]); i <- i + 2L; next
          }
          if (nx >= 48L && nx <= 55L) {                 # octal
            oct <- character(0); j <- i + 1L
            while (j <= n && b[j] >= 48L && b[j] <= 55L && length(oct) < 3L) {
              oct <- c(oct, intToUtf8(b[j])); j <- j + 1L
            }
            codes <- c(codes, strtoi(paste(oct, collapse = ""), 8L) %% 256L)
            i <- j; next
          }
          codes <- c(codes, nx); i <- i + 2L; next
        }
        if (c2 == 40L) depth <- depth + 1L
        if (c2 == 41L) {
          depth <- depth - 1L
          if (depth == 0L) { i <- i + 1L; break }
        }
        codes <- c(codes, c2); i <- i + 1L
      }
      pending <- c(pending, rhtp_pdf_decode(codes, cmap, two))
      next
    }

    if (ch == 60L && i < n && b[i + 1L] != 60L) {       # <hex string>
      j <- i + 1L
      hx <- character(0)
      while (j <= n && b[j] != 62L) {
        c2 <- b[j]
        if (!is_ws(c2)) hx <- c(hx, intToUtf8(c2))
        j <- j + 1L
      }
      h <- paste(hx, collapse = "")
      if (nchar(h) %% 2L == 1L) h <- paste0(h, "0")
      codes <- if (nchar(h) >= 2L) {
        strtoi(substring(h, seq(1, nchar(h) - 1, by = 2),
                         seq(2, nchar(h), by = 2)), 16L)
      } else integer(0)
      pending <- c(pending, rhtp_pdf_decode(codes, cmap, two))
      i <- j + 1L
      next
    }

    if (ch == 47L) {                                    # /Name
      j <- i + 1L
      while (j <= n && !is_ws(b[j]) && !is_dlm(b[j])) j <- j + 1L
      name <- paste(vapply(b[(i + 1L):(j - 1L)],
                           function(x) intToUtf8(x), character(1)),
                    collapse = "")
      # Is this the operand of a Tf? Look ahead past the size to the operator.
      k <- j
      while (k <= n && (is_ws(b[k]) || (b[k] >= 46L && b[k] <= 57L))) k <- k + 1L
      if (k + 1L <= n && b[k] == 84L && b[k + 1L] == 102L) {   # "Tf"
        f <- fonts[[name]]
        cmap <- if (is.null(f)) character() else f$cmap
        two  <- if (is.null(f)) FALSE else f$two_byte
      }
      i <- j
      next
    }

    if ((ch >= 65L && ch <= 90L) || (ch >= 97L && ch <= 122L) || ch == 42L) {
      j <- i
      while (j <= n && ((b[j] >= 65L && b[j] <= 90L) ||
                        (b[j] >= 97L && b[j] <= 122L) || b[j] == 42L)) {
        j <- j + 1L
      }
      op <- paste(vapply(b[i:(j - 1L)], function(x) intToUtf8(x), character(1)),
                  collapse = "")
      if (op %in% c("Tj", "TJ")) {
        buf <- c(buf, pending)
        pending <- character()
      } else if (op %in% c("Td", "TD", "T*", "ET")) {
        pending <- character()
        flush()
      } else if (op %in% c("BDC", "DP", "BMC")) {
        pending <- character()
      }
      i <- j
      next
    }

    i <- i + 1L
  }

  flush()
  lines
}


#' Extract the text of a PDF, one line per text-positioning operator
#'
#' @param path Path to the PDF.
#' @return A character vector of non-empty lines, in content order.
rhtp_pdf_text <- function(path) {
  bytes <- readBin(path, "raw", file.info(path)$size)
  objs  <- rhtp_pdf_objects(bytes)

  dict_ref <- function(body, key) {
    txt <- rhtp_pdf_chr(body)
    m <- regmatches(txt, regexec(paste0(key, "\\s+(\\d+)\\s+\\d+\\s+R"), txt,
                                 useBytes = TRUE))[[1]]
    if (length(m) < 2L) NULL else objs[[m[2]]]
  }

  # useBytes: these are binary regions, and a perl regex over a latin1 string
  # warns on every embedded font programme it walks past.
  pages <- Filter(function(b) grepl("/Type\\s*/Page[^s]",
                                    rhtp_pdf_chr(b[1:min(2000, length(b))]),
                                    perl = TRUE, useBytes = TRUE), objs)

  out <- character()
  for (page in pages) {
    ptxt <- rhtp_pdf_chr(page)

    res <- dict_ref(page, "/Resources")
    res_txt <- if (is.null(res)) ptxt else rhtp_pdf_chr(res)

    fonts <- list()
    fm <- regmatches(res_txt, regexec("/Font\\s*<<([^>]*)>>", res_txt))[[1]]
    font_dict <- if (length(fm) >= 2L) fm[2] else {
      fr <- dict_ref(if (is.null(res)) page else res, "/Font")
      if (is.null(fr)) "" else rhtp_pdf_chr(fr)
    }
    refs <- regmatches(font_dict, gregexpr("/(\\w+)\\s+(\\d+)\\s+\\d+\\s+R",
                                           font_dict))[[1]]
    for (r in refs) {
      p <- regmatches(r, regexec("/(\\w+)\\s+(\\d+)\\s+\\d+\\s+R", r))[[1]]
      fb <- objs[[p[3]]]
      if (is.null(fb)) next
      ftxt <- rhtp_pdf_chr(fb)
      tu <- dict_ref(fb, "/ToUnicode")
      fonts[[p[2]]] <- list(
        cmap = rhtp_pdf_tounicode(if (is.null(tu)) NULL else rhtp_pdf_stream(tu)),
        two_byte = grepl("/Identity-H", ftxt, fixed = TRUE, useBytes = TRUE) ||
                   grepl("/Type0", ftxt, fixed = TRUE, useBytes = TRUE)
      )
    }

    cm <- regmatches(ptxt, regexec("/Contents\\s*(\\[[^\\]]*\\]|\\d+\\s+\\d+\\s+R)",
                                   ptxt, perl = TRUE, useBytes = TRUE))[[1]]
    if (length(cm) < 2L) next
    cnums <- regmatches(cm[2], gregexpr("(\\d+)\\s+\\d+\\s+R", cm[2]))[[1]]
    stream <- raw(0)
    for (cn in cnums) {
      num <- regmatches(cn, regexec("(\\d+)", cn))[[1]][2]
      s <- rhtp_pdf_stream(objs[[num]])
      if (!is.null(s)) stream <- c(stream, s, charToRaw("\n"))
    }
    if (length(stream) == 0L) next

    out <- c(out, rhtp_pdf_content_lines(stream, fonts))
  }

  out <- trimws(out)
  out[nzchar(out)]
}
