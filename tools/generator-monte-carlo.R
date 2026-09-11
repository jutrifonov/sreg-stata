# Independent streams: this assesses sampling behavior, not row-level parity.
.libPaths(c(normalizePath('.build/rlib'),.libPaths()))
library(sreg)
rows <- list()
for (cluster in c(FALSE,TRUE)) for (i in 1:100) {
  set.seed(70000+i)
  n <- if(cluster) 200 else 1200
  d <- sreg.rgen(n=n,n.strata=4,tau.vec=.5,cluster=cluster)
  fit <- suppressWarnings(sreg(Y=d$Y,S=d$S,D=d$D,
    X=d[c('x_1','x_2')],G.id=if(cluster)d$G.id else NULL,
    Ng=if(cluster)d$Ng else NULL))
  rows[[length(rows)+1L]] <- data.frame(design=if(cluster)'cluster' else 'individual',
    replicate=i,estimate=fit$tau.hat,se=fit$se.rob)
}
write.csv(do.call(rbind,rows),'.build/generator-mc-r.csv',row.names=FALSE)
