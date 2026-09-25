# helper-s71.R -----------------------------------------------------------------
# Session 71. The committed state CSVs carry §10.2's enrolled-hospital-operator
# overlay (R/03bj), applied AFTER session 49's vq_overlay(). A test that checks
# "the committed CSV is the builder's output" chains s71() onto the build.
# Sourced into its own environment so none of 03bj's names leak into a test.
S71 <- new.env()
suppressMessages(source(here::here("R", "03bj_enrolled_hospital_operator.R"),
                        local = S71))
s71 <- function(d, f) S71$s71_overlay(d, f)
