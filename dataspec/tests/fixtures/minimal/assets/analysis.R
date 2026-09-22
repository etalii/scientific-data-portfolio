# Synthetic rate producer. Inputs: observations.csv; output: result.csv.
# This fixture is provenance text; the validator never executes it.
x <- read.csv("observations.csv")
x$rate <- x$count / x$population
