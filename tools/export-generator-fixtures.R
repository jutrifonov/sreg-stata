#!/usr/bin/env Rscript
# Compare deterministic design kernels using the unchanged installed R reference.
.libPaths(c(normalizePath('.build/rlib'), .libPaths()))
internal <- function(name) getFromNamespace(name, 'sreg')
vec <- function(x) paste0('(', paste(sprintf('%.17g', x), collapse='\\'), ')')
lines <- c('version 14.2', 'mata:')
w <- c(-2.2, -1.5, -1.125, -.5, 0, .5, 1.125, 1.5, 2.2)
for (h in c(1, 2, 4, 7)) {
  expected <- max.col(internal('form.strata.sreg')(list(Y.0=rep(0,length(w)), W=w), h))
  lines <- c(lines, sprintf('assert(sreg_rg_strata(%s,%d,0)==%s)', vec(w),h,vec(expected)))
  membership <- internal('form.strata.creg')(list(G=length(w),Z.g.2=w),h)
  # Explicitly repair only the excluded minimum, the documented native adaptation.
  stopifnot(sum(membership[1,])==0, all(rowSums(membership[-1,,drop=FALSE])==1))
  membership[1,1] <- 1
  lines <- c(lines,sprintf('assert(sreg_rg_strata(%s,%d,1)==%s)',vec(w),h,vec(max.col(membership))))
}
set.seed(901)
for (p in list(c(.6,.2,.2),c(.1,.3,.25,.35))) {
  for (n in c(2,7,20,73)) {
    # Compare allocation multisets; permutation RNG streams intentionally differ.
    for (name in c('gen.treat.sreg','gen.treat.creg')) {
      expected <- sort(internal(name)(matrix(p[-1],ncol=1),n,1))
      lines <- c(lines,sprintf('assert(sort(sreg_rg_assign(J(%d,1,1),(%s),J(1,0,.),0),1)==%s)',n,paste(p,collapse=','),vec(expected)))
    }
  }
}
lines <- c(lines,'end')
writeLines(lines,'.build/generator-reference.do')
