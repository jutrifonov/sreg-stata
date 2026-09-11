# Run the unchanged upstream tests and capture calls to the public estimator.
# Only the development harness instruments R; installed Stata never invokes R.
args <- commandArgs(TRUE)
root <- normalizePath(if (length(args)) args[1] else ".")
.libPaths(c(file.path(root, ".build/rlib"), .libPaths()))
library(sreg)
library(testthat)
library(dplyr)
library(tidyr)
library(purrr)
dir.create(file.path(root, ".build/captured"), recursive=TRUE, showWarnings=FALSE)
writeLines(as.character(getRversion()),file.path(root,".build/captured/r-version.txt"))
grDevices::pdf(file.path(root,".build/r-plots.pdf"))
.capture <- new.env(parent=emptyenv())
.capture$calls <- list()
.capture$file <- ""
.capture$test <- ""
.capture$test_id <- 0L
.capture$assertion_links <- list()
.original_sreg <- sreg::sreg
.record_sreg <- function(Y, S=NULL, D, G.id=NULL, Ng=NULL, X=NULL,
                         HC1=TRUE, small.strata=FALSE, k=NULL) {
    inputs <- as.list(environment())
    warnings <- character()
    error <- NULL
    result <- tryCatch(withCallingHandlers(do.call(.original_sreg, inputs),
        warning=function(w) warnings <<- c(warnings,conditionMessage(w))),
        error=function(e) { error <<- e; NULL })
    id <- length(.capture$calls)+1L
    .capture$calls[[id]] <- list(id=id,file=.capture$file,test=.capture$test,test_id=.capture$test_id,
        inputs=inputs,result=result,warnings=warnings,
        error=if(is.null(error)) NULL else conditionMessage(error))
    if (!is.null(error)) stop(error)
    result
}
assignInNamespace("sreg", .record_sreg, ns="sreg")
unlockBinding("sreg", as.environment("package:sreg"))
assign("sreg", .record_sreg, as.environment("package:sreg"))
lockBinding("sreg", as.environment("package:sreg"))
trace(testthat::test_that, tracer=quote({ .GlobalEnv$.capture$test <- desc; .GlobalEnv$.capture$test_id <- .GlobalEnv$.capture$test_id + 1L }),print=FALSE)
trace(testthat:::exp_signal, tracer=quote({
    .GlobalEnv$.capture$assertion_links[[length(.GlobalEnv$.capture$assertion_links)+1L]] <-
        list(test_id=.GlobalEnv$.capture$test_id,call_id=length(.GlobalEnv$.capture$calls),
             line=as.integer(exp$srcref)[1])
}), print=FALSE)
testenv <- new.env(parent=asNamespace("sreg"))
results <- list()
for (f in sort(list.files(file.path(root,"tests/upstream/tests/testthat"),
                         pattern="\\.R$",full.names=TRUE))) {
    .capture$file <- basename(f)
    results[[basename(f)]] <- testthat::test_file(f,env=testenv,reporter="summary",
                                               stop_on_failure=FALSE)
}
untrace(testthat::test_that)
untrace(testthat:::exp_signal)
saveRDS(.capture$assertion_links,file.path(root,".build/captured/assertion-links.rds"))
example_env <- new.env(parent=globalenv())
for(topic in c("sreg","sreg.rgen","print.sreg","plot.sreg")) {
    .capture$test_id <- 0L
    .capture$file <- "R documentation examples"
    .capture$test <- topic
    utils::example(topic,package="sreg",local=example_env,ask=FALSE,echo=FALSE,
                   character.only=TRUE)
}
grDevices::dev.off()
saveRDS(.capture$calls,file.path(root,".build/captured/calls.rds"))
saveRDS(results,file.path(root,".build/captured/test-results.rds"))
summary <- do.call(rbind,lapply(results,as.data.frame))
write.csv(summary[,setdiff(names(summary),"result")],file.path(root,".build/captured/r-tests.csv"),row.names=FALSE)
cat("\nCaptured",length(.capture$calls),"estimator calls.\n")
if(any(summary$failed>0 | summary$error)) quit(status=1)
