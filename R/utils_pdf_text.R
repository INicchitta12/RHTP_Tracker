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
# not enough to reconstruct a multi-column table. No encryption, no CID fonts
# without a CMap. A caller that needs more than a list of lines should not
# reach for this.
#
# WHAT SESSION 21 ADDED, AND WHY IT HAD TO BE ADDED RATHER THAN WORKED AROUND.
# Maryland publishes its Budget Period 1 award offers as PDFs written by a
# producer that puts every page object inside a COMPRESSED OBJECT STREAM
# (`/Type/ObjStm`) and every page's drawing inside a FORM XOBJECT that carries
# its own `/Font` resources. On such a file the old reader found `/Type/Page`
# nowhere, walked zero pages and returned CHARACTER(0) -- not an error, an
# empty answer, which is the failure mode this project cares about most: a
# caller that treated it as "the state published nothing" would have been
# wrong about a $73M award list. So two things are read now:
#
#   1. `/ObjStm` streams are inflated and their contained objects merged into
#      the object map, so page objects become visible. A top-level definition
#      of the same object number WINS, because an incremental update writes the
#      newer object at the top level.
#   2. A page's `Do` operators are followed into `/Subtype/Form` XObjects, each
#      decoded through ITS OWN font resources, in the order the operators
#      appear. Recursion is depth-capped and visit-marked, because a malformed
#      or hostile file can make a form reference itself.
#
# Page ORDER now comes from the document's own page tree (`/Type/Pages`,
# `/Kids`) when there is one. Object-number order is the fallback and it is not
# reliable on a file assembled by an incremental update.

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


#' Merge the objects held inside `/ObjStm` compressed object streams
#'
#' A PDF 1.5+ writer may pack non-stream objects -- page dictionaries among
#' them -- into a single Flate-compressed stream. `rhtp_pdf_objects()` scans
#' for `N G obj ... endobj` and cannot see those, so on such a file the page
#' walk finds nothing and returns an EMPTY result rather than failing. This
#' inflates every object stream and adds what it carries.
#'
#' A top-level object of the same number is kept in preference: an incremental
#' update writes the newer revision of an object at the top level, and the copy
#' inside an older object stream is the superseded one.
#'
#' @param objs The map from `rhtp_pdf_objects()`.
#' @return The same map, plus the objects recovered from any object streams.
rhtp_pdf_objstm_expand <- function(objs) {
  for (nm in names(objs)) {
    body <- objs[[nm]]
    # The dictionary only. Slicing a fixed number of bytes would drag the
    # compressed stream into the string and every regex below would then warn
    # about invalid UTF-8 on a region that is not text at all.
    s_at <- grepRaw("stream", body, all = FALSE)
    head_end <- if (length(s_at)) s_at - 1L else min(600L, length(body))
    if (head_end < 1L) next
    head_txt <- rhtp_pdf_chr(body[seq_len(head_end)])
    if (!grepl("/Type\\s*/ObjStm", head_txt, perl = TRUE, useBytes = TRUE)) next

    inflated <- rhtp_pdf_stream(body)
    if (is.null(inflated) || length(inflated) == 0L) next

    n_m     <- regmatches(head_txt, regexec("/N\\s+(\\d+)", head_txt, perl = TRUE))[[1]]
    first_m <- regmatches(head_txt, regexec("/First\\s+(\\d+)", head_txt, perl = TRUE))[[1]]
    if (length(n_m) < 2L || length(first_m) < 2L) next
    n_obj <- as.integer(n_m[2])
    first <- as.integer(first_m[2])
    if (is.na(n_obj) || is.na(first) || n_obj < 1L || first < 1L ||
        first > length(inflated)) next

    # The header is `num offset num offset ...`, 2N integers, all ASCII.
    pairs <- scan(text = rhtp_pdf_chr(inflated[seq_len(first)]), what = integer(),
                  quiet = TRUE, nmax = 2L * n_obj)
    if (length(pairs) < 2L * n_obj) next
    nums <- pairs[seq(1L, length(pairs), by = 2L)]
    offs <- pairs[seq(2L, length(pairs), by = 2L)]

    for (k in seq_len(n_obj)) {
      key <- as.character(nums[k])
      if (!is.null(objs[[key]])) next                  # top level wins
      from <- first + offs[k] + 1L
      to   <- if (k < n_obj) first + offs[k + 1L] else length(inflated)
      if (is.na(from) || is.na(to) || from > to || to > length(inflated)) next
      objs[[key]] <- inflated[from:to]
    }
  }
  objs
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

  # Accumulated as chunks and flattened once -- see the bfrange loop below.
  code_chunks <- list()
  val_chunks  <- list()
  n_chunk     <- 0L

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
      n_chunk <- n_chunk + 1L
      code_chunks[[n_chunk]] <- as.character(strtoi(p[2], 16L))
      val_chunks[[n_chunk]]  <- hex_to_str(p[3])
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
      # A bfrange is expanded WHOLE, not one c() at a time. A single range may
      # span thousands of codes -- an Identity-H subset routinely does -- and
      # growing two vectors element by element made this function 97.9% of the
      # reader's entire runtime on Indiana's 2026-08-21 award letter: 362 of
      # 370 seconds, all of it in c(). Same codes, same values, same order.
      ks <- lo:hi
      n_chunk <- n_chunk + 1L
      code_chunks[[n_chunk]] <- as.character(ks)
      val_chunks[[n_chunk]]  <- vapply(dst + ks - lo, intToUtf8, character(1))
    }
  }

  codes <- if (n_chunk) unlist(code_chunks, use.names = FALSE) else character()
  vals  <- if (n_chunk) unlist(val_chunks,  use.names = FALSE) else character()
  stats::setNames(vals, codes)
}


#' Decode a string operand through the current font
#'
#' A `/ToUnicode` CMap CAN BE INCOMPLETE, and a missing entry must not silently
#' delete a character. Georgia's DCH notices ship a single-byte font whose CMap
#' covers most of the alphabet and omits, among others, `H`: dropping the
#' unmapped codes turns "Crisp Regional Hospital" into "Crisp Regional ospital"
#' and "Colquitt" into "Coluitt" -- still readable, still plausible, and wrong
#' in a recipient name. So for a SINGLE-BYTE font an unmapped code falls back to
#' the code itself where that is printable ASCII, which is what the code means
#' in every single-byte encoding this project has met.
#'
#' The fallback is deliberately NOT extended to a two-byte (Identity-H) font:
#' there the code is a glyph id in a subsetted font and has no relation to any
#' character, so guessing would produce confident nonsense rather than a gap.
#' A CMap as a hash table, built once per font.
#'
#' WHY. `cmap[as.character(codes)]` is a name lookup on a character vector,
#' which R resolves by scanning the names. `rhtp_pdf_decode()` runs once per
#' string operand, and a Word-exported PDF emits one per GLYPH -- so on
#' Indiana's 2026-08-21 award letter the reader scanned a several-thousand-entry
#' CMap tens of thousands of times. An environment lookup is O(1) and the
#' answers are identical: same keys, same values, `NA` where the CMap has no
#' entry (which is what the ASCII fallback in `rhtp_pdf_decode()` keys on).
rhtp_pdf_cmap_env <- function(cmap) {
  e <- new.env(hash = TRUE, parent = emptyenv(), size = max(29L, length(cmap)))
  if (length(cmap)) list2env(as.list(cmap), envir = e)
  e
}

rhtp_pdf_cmap_get <- function(env, keys) {
  vapply(keys, function(k) {
    v <- env[[k]]
    if (is.null(v)) NA_character_ else v
  }, character(1), USE.NAMES = FALSE)
}

rhtp_pdf_decode <- function(codes, cmap, two_byte, cmap_env = NULL) {
  if (length(codes) == 0L) return("")
  codes <- codes[!is.na(codes)]
  if (length(codes) == 0L) return("")

  ascii <- function(x) {
    vapply(x, function(k) if (k >= 32L && k < 256L) intToUtf8(k) else "",
           character(1))
  }

  if (length(cmap) == 0L) {
    return(paste(ascii(codes), collapse = ""))
  }
  if (isTRUE(two_byte)) {
    if (length(codes) < 2L) return("")
    idx <- seq(1L, length(codes) - 1L, by = 2L)
    codes <- codes[idx] * 256L + codes[idx + 1L]
    out <- if (is.null(cmap_env)) unname(cmap[as.character(codes)])
           else rhtp_pdf_cmap_get(cmap_env, as.character(codes))
    return(paste(ifelse(is.na(out), "", out), collapse = ""))
  }
  out <- if (is.null(cmap_env)) unname(cmap[as.character(codes)])
         else rhtp_pdf_cmap_get(cmap_env, as.character(codes))
  paste(ifelse(is.na(out), ascii(codes), out), collapse = "")
}


#' Scan one content stream and emit its text, one line per text position
#'
#' Operates on integer byte codes rather than a string: in a two-byte glyph
#' code the high byte is very often NUL, and `rawToChar()` cannot hold one.
#'
#' A LINE IS A VERTICAL POSITION, NOT A `Td`. The first version of this broke a
#' line at every text-positioning operator, which is right for KDHE's bulleted
#' lists and catastrophic for Maryland's: its producer emits a separate
#' `BT ... ET` block per word and a `Td` per GLYPH, all at the same y, so
#' "Maryland" came out as eight lines of one character. So the scanner tracks
#' the text position's vertical component -- `Tm`'s f, plus the accumulated `ty`
#' of the `Td`/`TD` operators since the last `BT` -- and breaks only when that
#' value CHANGES. Horizontal movement within a line no longer breaks it.
#'
#' THIS DOES CHANGE THE LINES KANSAS'S PDFs PRODUCE, and the claim that matters
#' was checked rather than assumed. KDHE's files wrap mid-word, so the old
#' reader emitted "Citizens Foundat" and "ion: $146,476" as two lines and
#' `R/03o` re-joined them; the new one emits the whole visual line and the
#' re-join finds nothing to do. `data/reference/ks_year1_awardees.csv` REBUILDS
#' BYTE-IDENTICAL under both readers -- 46 rows, $80,020,499 -- which is the
#' assertion, not the intermediate line count.
#' isTRUE(all.equal(target, current)) for two finite scalars, without the
#' generic dispatch.
#'
#' WHY THIS EXISTS. `at_y()` runs once per text-positioning operator, and a
#' Word-exported PDF emits one per GLYPH -- so on Indiana's 2026-08-21 award
#' letter `all.equal()` was called tens of thousands of times and was the single
#' largest cost in the reader. This reproduces `all.equal.numeric`'s default
#' behaviour for the scalar case exactly: a relative comparison scaled by
#' |target| once that exceeds the tolerance, an absolute one below it.
rhtp_pdf_near <- function(target, current,
                          tolerance = sqrt(.Machine$double.eps)) {
  d <- abs(target - current)
  # Exact and cheap: anything this far apart differs under any of all.equal's
  # branches, because the relative branch only ever makes the ratio larger for
  # |target| <= 1.
  if (is.finite(d) && is.finite(target)) {
    scale <- abs(target)
    if (scale > 1 && d / scale > tolerance) return(FALSE)
    if (scale > 1 && d == 0) return(TRUE)
    if (scale <= 1 && d > tolerance) return(FALSE)
    if (scale <= 1 && d == 0) return(TRUE)
  }
  # Everything left is within a hair of the tolerance boundary, where
  # all.equal's relative/absolute switch is the only thing that decides it.
  # PDF text coordinates never land here; correctness does not depend on that.
  isTRUE(all.equal(target, current, tolerance = tolerance))
}

rhtp_pdf_content_lines <- function(stream, fonts) {
  b <- as.integer(stream)
  n <- length(b)
  if (n == 0L) return(character())

  # Accumulated as LISTS and flattened once at the end. These were grown with
  # c() per emitted line, which is O(n^2): Indiana's 2026-08-21 award letter is
  # a Word export that emits a Td per glyph, so a 280 KB content stream emits
  # tens of thousands of lines and the copying dominated everything else. The
  # values and their order are unchanged -- see rhtp_pdf_near() below.
  lines_l <- list()
  xs_l    <- list()
  ys_l    <- list()
  n_out   <- 0L
  buf     <- character()
  # Strings are held here until a Tj/TJ actually paints them. A PDF also
  # carries strings that are never drawn -- /ActualText and /Alt inside
  # marked-content property lists -- and appending those straight to the line
  # buffer sprinkles stray glyphs through the output.
  pending <- character()
  cmap  <- character()
  cmap_e <- NULL
  two   <- FALSE
  i     <- 1L

  # The text position's vertical component, and the numeric operands seen
  # since the last operator. `y_m` is Tm's f; `y_d` accumulates Td/TD's ty,
  # which is relative to the line matrix and resets with each BT/Tm.
  nums  <- numeric(0)
  y_m   <- 0
  y_d   <- 0
  x_m   <- 0
  x_d   <- 0
  y_at  <- NA_real_          # the y the current buffer is being written at
  x_at  <- NA_real_          # and the x it started at, for column bucketing
  # The graphics state's vertical translation, and the q/Q stack that restores
  # it. Maryland draws each TABLE CELL inside its own `q .75 0 0 .75 x y cm`,
  # with the same text matrix every time, so without this every cell in the
  # document lands on one line. Only the translation is tracked, not the full
  # matrix: this reader needs to know when the pen moved DOWN, not where it is.
  ctm_y <- 0
  ctm_x <- 0
  ctm_stack <- list()

  is_ws  <- function(x) x %in% c(32L, 13L, 10L, 9L, 12L, 0L)
  is_dlm <- function(x) x %in% c(40L, 41L, 60L, 62L, 91L, 93L, 47L, 37L,
                                 123L, 125L)

  flush <- function() {
    if (length(buf)) {
      n_out <<- n_out + 1L
      lines_l[[n_out]] <<- paste(buf, collapse = "")
      xs_l[[n_out]]    <<- x_at
      ys_l[[n_out]]    <<- y_at
      buf <<- character()
    }
  }

  # Break the line only if the text position has actually moved vertically.
  at_y <- function() {
    y <- ctm_y + y_m + y_d
    if (is.na(y_at) || !rhtp_pdf_near(y, y_at)) {
      flush()
      y_at <<- y
      x_at <<- ctm_x + x_m + x_d
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
      pending <- c(pending, rhtp_pdf_decode(codes, cmap, two, cmap_e))
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
      pending <- c(pending, rhtp_pdf_decode(codes, cmap, two, cmap_e))
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
        cmap_e <- if (is.null(f)) NULL else f$cmap_env
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
        # The line break is decided HERE, where text is actually painted, not
        # at the positioning operators: a producer that emits Tm and Td for
        # every word would otherwise break the line between the operator that
        # moves and the operator that draws.
        at_y()
        buf <- c(buf, pending)
        pending <- character()
      } else if (op %in% c("Td", "TD")) {
        pending <- character()
        if (length(nums) >= 2L) {
          y_d <- y_d + nums[length(nums)]
          x_d <- x_d + nums[length(nums) - 1L]
        }
      } else if (op == "Tm") {
        pending <- character()
        if (length(nums) >= 6L) {
          y_m <- nums[length(nums)]
          x_m <- nums[length(nums) - 1L]
        }
        y_d <- 0
        x_d <- 0
      } else if (op == "BT") {
        pending <- character()
        y_m <- 0
        y_d <- 0
        x_m <- 0
        x_d <- 0
      } else if (op == "cm") {
        if (length(nums) >= 6L) {
          ctm_y <- ctm_y + nums[length(nums)]
          ctm_x <- ctm_x + nums[length(nums) - 1L]
        }
      } else if (op == "q") {
        ctm_stack[[length(ctm_stack) + 1L]] <- c(ctm_x, ctm_y)
      } else if (op == "Q") {
        if (length(ctm_stack)) {
          last <- ctm_stack[[length(ctm_stack)]]
          ctm_x <- last[1]; ctm_y <- last[2]
          ctm_stack[[length(ctm_stack)]] <- NULL
        }
      } else if (op == "T*") {
        # A move to the next line by an amount this reader does not track.
        pending <- character()
        flush()
        y_at <- NA_real_
      } else if (op == "ET") {
        pending <- character()
      } else if (op %in% c("BDC", "DP", "BMC")) {
        pending <- character()
      }
      if (op != "Tj" && op != "TJ") nums <- numeric(0)
      i <- j
      next
    }

    if ((ch >= 48L && ch <= 57L) || ch == 45L || ch == 43L || ch == 46L) {
      j <- i
      while (j <= n && ((b[j] >= 48L && b[j] <= 57L) || b[j] == 45L ||
                        b[j] == 43L || b[j] == 46L)) j <- j + 1L
      v <- suppressWarnings(as.numeric(paste(
        vapply(b[i:(j - 1L)], function(x) intToUtf8(x), character(1)),
        collapse = "")))
      if (!is.na(v)) nums <- c(nums, v)
      i <- j
      next
    }

    i <- i + 1L
  }

  flush()
  if (n_out == 0L) {
    return(data.frame(x = numeric(0), y = numeric(0), text = character(0),
                      stringsAsFactors = FALSE))
  }
  data.frame(x = unlist(xs_l, use.names = FALSE),
             y = unlist(ys_l, use.names = FALSE),
             text = unlist(lines_l, use.names = FALSE),
             stringsAsFactors = FALSE)
}


#' Extract a PDF's text lines, with the position each was drawn at
#'
#' @param path Path to the PDF.
#' @return A data frame of `page`, `x`, `y`, `text`, in content order, one row
#'   per visual line. `x` is what tells a table's columns apart -- Maryland's
#'   award tables put the recipient, the amount, the summary and the counties
#'   at four stable x values, and nothing in the content ORDER separates them.
rhtp_pdf_lines <- function(path) {
  bytes <- readBin(path, "raw", file.info(path)$size)
  objs  <- rhtp_pdf_objstm_expand(rhtp_pdf_objects(bytes))

  # -- small readers over the object map ------------------------------------

  # An object body, minus its stream: the dictionary is all these regexes want,
  # and running them over an inflated font programme is both slow and a source
  # of accidental matches.
  header_of <- function(body) {
    if (is.null(body)) return("")
    s <- grepRaw("stream", body, all = FALSE)
    end <- if (length(s)) s - 1L else length(body)
    if (end < 1L) return("")
    rhtp_pdf_chr(body[seq_len(min(end, 20000L))])
  }

  ref_body <- function(txt, key) {
    m <- regmatches(txt, regexec(paste0(key, "\\s+(\\d+)\\s+\\d+\\s+R"), txt,
                                 perl = TRUE, useBytes = TRUE))[[1]]
    if (length(m) < 2L) NULL else objs[[m[2]]]
  }

  # The text of a resource dictionary, whether it is written inline in the
  # object or referenced. Both forms occur in the same corpus: SharePoint's
  # writer references it, Maryland's writes it inline inside an object stream.
  resources_txt <- function(owner_txt) {
    r <- ref_body(owner_txt, "/Resources")
    if (!is.null(r)) header_of(r) else owner_txt
  }

  #' The /Font map of a resource dictionary, as name -> {cmap, two_byte}
  fonts_of <- function(res_txt) {
    fonts <- list()
    fm <- regmatches(res_txt, regexec("/Font\\s*<<([^>]*)>>", res_txt,
                                     useBytes = TRUE))[[1]]
    font_dict <- if (length(fm) >= 2L) fm[2] else {
      fr <- ref_body(res_txt, "/Font")
      if (is.null(fr)) "" else header_of(fr)
    }
    refs <- regmatches(font_dict, gregexpr("/(\\w+)\\s+(\\d+)\\s+\\d+\\s+R",
                                           font_dict, useBytes = TRUE))[[1]]
    for (r in refs) {
      p <- regmatches(r, regexec("/(\\w+)\\s+(\\d+)\\s+\\d+\\s+R", r,
                                 useBytes = TRUE))[[1]]
      fb <- objs[[p[3]]]
      if (is.null(fb)) next
      ftxt <- header_of(fb)
      tu <- ref_body(ftxt, "/ToUnicode")
      fcmap <- rhtp_pdf_tounicode(if (is.null(tu)) NULL else rhtp_pdf_stream(tu))
      fonts[[p[2]]] <- list(
        cmap = fcmap,
        cmap_env = rhtp_pdf_cmap_env(fcmap),
        two_byte = grepl("/Identity-H", ftxt, fixed = TRUE, useBytes = TRUE) ||
                   grepl("/Type0", ftxt, fixed = TRUE, useBytes = TRUE)
      )
    }
    fonts
  }

  # The concatenated /Contents streams of a page.
  contents_stream <- function(owner_txt) {
    cm <- regmatches(owner_txt,
                     regexec("/Contents\\s*(\\[[^\\]]*\\]|\\d+\\s+\\d+\\s+R)",
                             owner_txt, perl = TRUE, useBytes = TRUE))[[1]]
    if (length(cm) < 2L) return(raw(0))
    cnums <- regmatches(cm[2], gregexpr("(\\d+)\\s+\\d+\\s+R", cm[2],
                                        useBytes = TRUE))[[1]]
    stream <- raw(0)
    for (cn in cnums) {
      num <- regmatches(cn, regexec("(\\d+)", cn, useBytes = TRUE))[[1]][2]
      s <- rhtp_pdf_stream(objs[[num]])
      if (!is.null(s)) stream <- c(stream, s, charToRaw("\n"))
    }
    stream
  }

  # -- content, following Do into form XObjects ------------------------------

  # A page's own text, then each form XObject it invokes, in the order the `Do`
  # operators appear. `seen` stops a form that references itself; `depth` caps
  # a chain of forms that reference each other.
  empty_lines <- data.frame(x = numeric(0), y = numeric(0),
                            text = character(0), stringsAsFactors = FALSE)

  lines_for <- function(stream, res_txt, seen = character(), depth = 0L) {
    if (length(stream) == 0L) return(empty_lines)
    out <- rhtp_pdf_content_lines(stream, fonts_of(res_txt))
    if (depth >= 8L) return(out)

    ctxt <- rhtp_pdf_chr(stream)
    dos  <- regmatches(ctxt, gregexpr("/([A-Za-z0-9_.#-]+)\\s+Do\\b", ctxt,
                                      perl = TRUE, useBytes = TRUE))[[1]]
    if (length(dos) == 0L) return(out)

    xm <- regmatches(res_txt, regexec("/XObject\\s*<<([^>]*)>>", res_txt,
                                      useBytes = TRUE))[[1]]
    xdict <- if (length(xm) >= 2L) xm[2] else {
      xr <- ref_body(res_txt, "/XObject")
      if (is.null(xr)) "" else header_of(xr)
    }
    if (!nzchar(xdict)) return(out)

    for (d in dos) {
      nm <- regmatches(d, regexec("/([A-Za-z0-9_.#-]+)", d, useBytes = TRUE))[[1]][2]
      hit <- regmatches(xdict, regexec(paste0("/", nm, "\\s+(\\d+)\\s+\\d+\\s+R"),
                                       xdict, perl = TRUE, useBytes = TRUE))[[1]]
      if (length(hit) < 2L) next
      key <- hit[2]
      if (key %in% seen) next
      xb <- objs[[key]]
      if (is.null(xb)) next
      xtxt <- header_of(xb)
      if (!grepl("/Subtype\\s*/Form", xtxt, perl = TRUE, useBytes = TRUE)) next
      xs <- rhtp_pdf_stream(xb)
      if (is.null(xs)) next
      out <- rbind(out, lines_for(xs, resources_txt(xtxt), c(seen, key),
                                  depth + 1L))
    }
    out
  }

  # -- pages, in the document's own order ------------------------------------

  is_page <- function(body) {
    grepl("/Type\\s*/Page[^s]", header_of(body), perl = TRUE, useBytes = TRUE)
  }

  # Walk /Type/Pages -> /Kids. Object-number order is only the fallback: on a
  # file assembled by an incremental update it is not page order.
  page_keys_from_tree <- function() {
    is_pages <- vapply(objs, function(b)
      grepl("/Type\\s*/Pages\\b", header_of(b), perl = TRUE, useBytes = TRUE),
      logical(1))
    if (!any(is_pages)) return(character())
    roots <- names(objs)[is_pages &
      !vapply(objs, function(b) grepl("/Parent\\s+\\d+\\s+\\d+\\s+R",
                                      header_of(b), perl = TRUE,
                                      useBytes = TRUE), logical(1))]
    if (length(roots) == 0L) roots <- names(objs)[is_pages][1]

    walk <- function(key, seen) {
      if (key %in% seen || is.null(objs[[key]])) return(character())
      seen <- c(seen, key)
      txt <- header_of(objs[[key]])
      if (is_page(objs[[key]])) return(key)
      km <- regmatches(txt, regexec("/Kids\\s*\\[([^\\]]*)\\]", txt, perl = TRUE))[[1]]
      if (length(km) < 2L) return(character())
      kids <- regmatches(km[2], gregexpr("(\\d+)\\s+\\d+\\s+R", km[2]))[[1]]
      unlist(lapply(kids, function(k)
        walk(regmatches(k, regexec("(\\d+)", k))[[1]][2], seen)), use.names = FALSE)
    }
    unique(unlist(lapply(roots[1], walk, seen = character()), use.names = FALSE))
  }

  keys <- page_keys_from_tree()
  if (length(keys) == 0L) keys <- names(objs)[vapply(objs, is_page, logical(1))]

  out <- empty_lines
  out$page <- integer(0)
  pno <- 0L
  for (key in keys) {
    page  <- objs[[key]]
    if (is.null(page)) next
    pno   <- pno + 1L
    ptxt  <- header_of(page)
    got <- lines_for(contents_stream(ptxt), resources_txt(ptxt))
    if (nrow(got)) {
      got$page <- pno
      out <- rbind(out, got)
    }
  }

  out$text <- trimws(out$text)
  out <- out[nzchar(out$text), , drop = FALSE]
  rownames(out) <- NULL
  out[, c("page", "x", "y", "text")]
}


#' The text of a PDF as a plain character vector, in content order
#'
#' The convenience wrapper over `rhtp_pdf_lines()` that every caller before
#' Maryland used. Keep using it unless you need the geometry: a table whose
#' columns must be told apart needs `x`, and nothing else does.
#'
#' @param path Path to the PDF.
#' @return A character vector of non-empty lines, in content order.
rhtp_pdf_text <- function(path) {
  rhtp_pdf_lines(path)$text
}
