# Audit original executed expectations, retaining their source positions.
x <- readRDS('.build/captured/test-results.rds')
rows <- list()
id <- 0L
for (file in names(x)) for (test in x[[file]]) {
  id <- id+1L
  source <- readLines(file.path('tests/upstream/tests/testthat',file),warn=FALSE)
  for (i in seq_along(test$results)) {
    e <- test$results[[i]]
    pos <- as.integer(e$srcref)
    expr <- if(length(pos)) paste(source[pos[1]:pos[3]],collapse=' ') else ''
    type <- regmatches(expr,regexpr('expect_[a-z0-9_]+',expr))
    rows[[length(rows)+1L]] <- data.frame(test_id=id,file=file,test=test$test,
      assertion=i,line=if(length(pos))pos[1] else NA,
      expectation=if(length(type))type else 'unknown',
      result=class(e)[1],source=expr)
  }
}
write.csv(do.call(rbind,rows),'.build/r-assertion-audit.csv',row.names=FALSE)
