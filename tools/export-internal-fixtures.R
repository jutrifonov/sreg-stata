root <- normalizePath(".")
.libPaths(c(file.path(root,".build/rlib"),.libPaths()))
library(sreg)
library(testthat)
.internal_calls <- list()
.origvar <- get("as.var.creg",asNamespace("sreg"))
.capturevar <- function(model=NULL,fit,HC1) {
    result <- .origvar(model,fit,HC1)
    .internal_calls[[length(.internal_calls)+1L]] <<- list(model=model,fit=fit,hc=HC1,se=result)
    result
}
assignInNamespace("as.var.creg",.capturevar,"sreg")
.legacy_bounds <- numeric()
trace(testthat::expect_gt,exit=quote(.GlobalEnv$.legacy_bounds <- c(.GlobalEnv$.legacy_bounds,expected)),print=FALSE)
testthat::test_file("tests/upstream/tests/testthat/test-cluster-large-variance.R",
    env=new.env(parent=asNamespace("sreg")),reporter="summary",stop_on_failure=TRUE)
untrace(testthat::expect_gt)
stopifnot(length(.legacy_bounds)==length(.internal_calls))
lines <- c('clear all','set more off','quietly do ado/sreg_mata.mata')
for(j in seq_along(.internal_calls)) {
    r <- .internal_calls[[j]]; f <- r$fit; n <- length(f$Ng)
    mu <- if(is.null(r$model)) matrix(0,n,2) else f$mu.hat[[1]]
    dat <- data.frame(T=f$Y.bar.g*f$Ng,S=f$data.list[[1]]$S,D=f$data.list[[1]]$D,
        N=f$Ng,mu0=mu[,1],mu1=mu[,2],pi0=f$pi.hat.0,pi1=f$pi.hat[[1]])
    file <- sprintf(".build/fixtures/internal-%d.csv",j)
    write.table(dat,file,sep=",",row.names=FALSE,quote=FALSE)
    lines <- c(lines,sprintf('import delimited using "%s", clear case(preserve) asdouble',file),
        'mata: z=st_data(.,tokens("T S D N mu0 mu1 pi0 pi1"))',
        sprintf('mata: VV=sreg_large_variance(z[,1],z[,2],z[,3],z[,4],(z[,5],z[,6],J(rows(z),1,0)),(z[,7],z[,8],J(rows(z),1,1/3)),(%s),%d)',sprintf('%.17g',f$tau.hat),r$hc),
        sprintf('mata: assert(abs(sqrt(VV[1,1])-(%.17g))<1e-12)',r$se),
        sprintf('mata: assert(sqrt(VV[1,1]) > %.17g)',.legacy_bounds[j]))
}
.small_calls <- list()
.origtau <- get("tau.hat.creg.ss",asNamespace("sreg"))
.origsmallvar <- get("as.var.creg.ss",asNamespace("sreg"))
.capturetau <- function(Y,D,X=NULL,S,G.id,Ng) {
    inputs <- as.list(environment())
    result <- do.call(.origtau,inputs)
    .small_calls[[length(.small_calls)+1L]] <<- list(inputs=inputs,b=result$tau.hat,hc=FALSE)
    result
}
.capturesmallvar <- function(Y,D,X=NULL,S,G.id,Ng,fit=NULL,HC1=TRUE) {
    inputs <- as.list(environment())
    result <- do.call(.origsmallvar,inputs)
    .small_calls[[length(.small_calls)+1L]] <<- list(inputs=inputs,se=sqrt(result/length(unique(G.id))),hc=HC1)
    result
}
assignInNamespace("tau.hat.creg.ss",.capturetau,"sreg")
assignInNamespace("as.var.creg.ss",.capturesmallvar,"sreg")
testthat::test_file("tests/upstream/tests/testthat/test-cluster-small-correction.R",
    env=new.env(parent=asNamespace("sreg")),reporter="summary",stop_on_failure=TRUE)
lines <- c(lines,'adopath ++ "ado"')
for(j in seq_along(.small_calls)) {
    r <- .small_calls[[j]]; x <- r$inputs
    dat <- data.frame(Y=x$Y,S=x$S,D=x$D,G_id=x$G.id)
    opts <- ""
    if(!is.null(x$Ng)) { dat$Ng <- x$Ng; opts <- "clustersize(Ng)" }
    xn <- character()
    if(!is.null(x$X)) {
        X <- as.data.frame(x$X)
        xn <- paste0("x",seq_len(ncol(X)))
        for(k in seq_along(xn)) dat[[xn[k]]] <- X[[k]]
    }
    file <- sprintf(".build/fixtures/small-internal-%d.csv",j)
    write.table(dat,file,sep=",",row.names=FALSE,quote=FALSE)
    lines <- c(lines,sprintf('import delimited using "%s", clear case(preserve) asdouble',file),
        paste('sreg Y',paste(xn,collapse=" "),', treatment(D) strata(S) cluster(G_id) smallstrata',opts,if(r$hc) '' else 'nohc1'))
    values <- if(is.null(r$b)) r$se else r$b
    type <- if(is.null(r$b)) "_se" else "_b"
    lines <- c(lines,sprintf('mata: assert(cols(st_matrix("e(b)"))==%d)',length(values)))
    for(k in seq_along(values)) {
        lines <- c(lines,sprintf('assert abs(%s[tau%d]-(%.17g))<1e-10',type,k,values[k]))
        if(type=='_se') lines <- c(lines,sprintf('assert _se[tau%d]>0 & _se[tau%d]<.',k,k))
    }
}
lines <- c(lines,
    '* Direct translations of the three upstream design-classifier tests.',
    'mata: assert(sreg_modal((2\\4\\5\\6),.)==2)',
    'mata: assert(sreg_modal((3\\3\\3\\3\\8),.)==3)',
    'capture mata: sreg_modal((2\\4\\5\\6\\7),.)',
    'assert _rc!=0',
    'mata: assert(sreg_modal((4\\4\\4\\4\\8),4)==4)',
    'file open done using ".build/internal.done", write replace',
    'file write done "PASS"','file close done','exit, clear')
writeLines(lines,".build/internal.do")
