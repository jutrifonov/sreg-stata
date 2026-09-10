args <- commandArgs(TRUE)
root <- normalizePath(if(length(args)) args[1] else ".")
calls <- readRDS(file.path(root,".build/captured/calls.rds"))
dest <- file.path(root,".build/fixtures")
dir.create(dest,recursive=TRUE,showWarnings=FALSE)
fmt <- function(x) ifelse(is.finite(x),sprintf("%.17g",x),".")
lines <- c('clear all','set more off','set type double','adopath ++ "ado"',
    'file open report using ".build/parity-results.csv", write replace',
    'file write report "id,kind,passed" _n')
manifest <- list()
for(call in calls) {
    x <- call$inputs
    nonnull <- x[c("Y","S","D","G.id","Ng","X")]
    supported <- all(vapply(nonnull,function(v) is.null(v)||is.numeric(v)||is.matrix(v)||is.data.frame(v),logical(1)))
    status <- if(!supported) "R container/type validation; covered by native parser tests" else "exported"
    manifest[[length(manifest)+1]] <- data.frame(id=call$id,file=call$file,test=call$test,status=status)
    if(!supported) next
    dat <- list()
    for(nm in c("Y","S","D","G.id","Ng")) if(!is.null(x[[nm]])) dat[[gsub("\\.","_",nm)]] <- as.numeric(unlist(x[[nm]]))
    if(!is.null(x$X)) {
        cov <- as.data.frame(x$X)
        for(j in seq_len(ncol(cov))) dat[[paste0("x",j)]] <- as.numeric(cov[[j]])
    }
    if(!length(dat)) next
    df <- as.data.frame(dat)
    path <- sprintf(".build/fixtures/case-%04d.csv",call$id)
    write.table(df,file.path(root,path),sep=",",row.names=FALSE,col.names=TRUE,na="",quote=FALSE)
    opts <- character()
    for(pair in list(c("Y","y"),c("S","s"),c("D","d"),c("G.id","g_id"),c("Ng","ng")))
        if(!is.null(x[[pair[1]]])) opts <- c(opts,sprintf("%s(%s)",pair[2],gsub("\\.","_",pair[1])))
    if(!is.null(x$X)) opts <- c(opts,paste0("x(",paste(paste0("x",seq_len(ncol(as.data.frame(x$X)))),collapse=" "),")"))
    opts <- c(opts,if(is.logical(x$HC1) && length(x$HC1)==1 && !is.na(x$HC1)) paste0("hc1(",tolower(x$HC1),")") else "hc1(invalid)")
    if(isTRUE(x$small.strata)) opts <- c(opts,"smallstrata")
    else if(!identical(x$small.strata,FALSE)) opts <- c(opts,"invalidsmallstrata")
    if(!is.null(x$k)) opts <- c(opts,paste0("k(",x$k,")"))
    command <- paste("sreg,",paste(opts,collapse=" "))
    lines <- c(lines,sprintf('* R call %d: %s',call$id,call$test),
        sprintf('import delimited using "%s", clear case(preserve) asdouble',path),
        paste('capture noisily',command),'local code = _rc')
    if(!is.null(call$error)) {
        lines <- c(lines,'local passed = (`code\' != 0)',sprintf('file write report "%d,error,`passed\'" _n',call$id))
        next
    }
    fit <- call$result
    if(any(!is.finite(c(fit$tau.hat,fit$se.rob)))) {
        lines <- c(lines,'local passed = (`code\' != 0)',sprintf('file write report "%d,undefined_inference,`passed\'" _n',call$id))
        next
    }
    checks <- character()
    for(j in seq_along(fit$tau.hat)) {
        checks <- c(checks,sprintf('abs(_b[tau%d]-(%s)) <= 1e-8*(1+abs(%s))',j,fmt(fit$tau.hat[j]),fmt(fit$tau.hat[j])),
            sprintf('abs(_se[tau%d]-(%s)) <= 1e-8*(1+abs(%s))',j,fmt(fit$se.rob[j]),fmt(fit$se.rob[j])))
    }
    checks <- c(checks,sprintf('e(N)==%d',nrow(fit$data)),sprintf('e(adjusted)==%d',!is.null(fit$lin.adj)))
    checks <- c(checks,sprintf('e(N_strata)==%d',length(unique(fit$data$S))),
        sprintf('e(N_treatments)==%d',length(fit$tau.hat)),
        sprintf('e(HC1)==%d',isTRUE(fit$HC1)),
        sprintf('e(smallstrata)==%d',isTRUE(fit$small.strata)))
    design <- if(isTRUE(fit$mixed.design)) "mixed design" else if(isTRUE(fit$small.strata)) "small strata" else "large strata"
    checks <- c(checks,sprintf('"`e(design)\'"=="%s"',design))
    if(!is.null(fit$data$G.id)) checks <- c(checks,sprintf('e(N_clust)==%d',length(unique(fit$data$G.id))))
    if(isTRUE(fit$small.strata)) {
        small <- if(isTRUE(fit$mixed.design)) fit$res.small$data else fit$data
        sz <- if(is.null(small$G.id)) table(small$S) else table(unique(small[c("S","G.id")])$S)
        checks <- c(checks,sprintf('e(k)==%d',as.integer(sz[1])))
    }
    warning_map <- c("Mixed design detected"="Mixed design detected",
        "Cluster sizes have not been provided"="Cluster sizes have not been provided",
        "ignoring these values"="Missing observations omitted",
        "covariates do not vary"="covariates do not vary",
        "individual-level covariates"="individual-level covariates",
        "All strata have the same small number"="All strata have the same small number",
        "At least 25% of strata"="At least 25% of strata",
        "HC1 adjustment unstable"="HC1 adjustment unstable")
    for(pattern in names(warning_map)) if(any(grepl(pattern,call$warnings,fixed=TRUE)))
        checks <- c(checks,sprintf('strpos(`"`e(warnings)\'"\',"%s")>0',warning_map[[pattern]]))
    lines <- c(lines,'local passed = 0','if `code\' == 0 {','    local passed = 1')
    for(check in checks) lines <- c(lines,paste('    capture assert',check),'    if _rc local passed = 0')
    # Stata displays z statistics and normal-reference p-values and intervals.
    lines <- c(lines,'    matrix inference = r(table)')
    for(j in seq_along(fit$tau.hat)) for(pair in list(c(3,fit$t.stat[j]),c(4,fit$p.value[j]),c(5,fit$CI.left[j]),c(6,fit$CI.right[j])))
        lines <- c(lines,sprintf('    capture assert abs(inference[%d,%d]-(%s)) <= 1e-8*(1+abs(%s))',pair[1],j,fmt(pair[2]),fmt(pair[2])),
                    '    if _rc local passed = 0')
    large_beta <- function(models, strata_order=seq_len(nrow(models[[1]]))) do.call(rbind,lapply(strata_order,function(s)
        do.call(rbind,lapply(models,function(m)m[s,,drop=FALSE]))))
    slopes <- list()
    if(!is.null(fit$beta.hat)) slopes$beta <- as.matrix(fit$beta.hat)
    else if(!is.null(fit$ols.iter)) slopes$beta <- large_beta(fit$ols.iter)
    if(isTRUE(fit$mixed.design) && !is.null(fit$lin.adj)) {
        slopes$beta_small <- as.matrix(fit$beta.hat)
        # R renumbers the large component by first appearance; native output
        # orders component strata by their original numeric labels.
        big_labels <- unique(fit$data$S[fit$data$stratum_type=="big"])
        slopes$beta_large <- large_beta(fit$ols.iter,order(big_labels))
    }
    for(name in names(slopes)) {
        m <- slopes[[name]]
        literal <- paste(apply(m,1,function(row)paste(fmt(row),collapse=",")),collapse="\\")
        lines <- c(lines,sprintf('    matrix sb = e(%s)',name),
            sprintf('    matrix rb = (%s)',literal),
            '    capture assert mreldif(sb,rb)<1e-8','    if _rc local passed = 0')
    }
    if(isTRUE(fit$mixed.design)) {
        for(comp in c("small","big")) {
            mat <- if(comp=="small") "small" else "large"
            r <- fit[[paste0("res.",comp)]]
            lines <- c(lines,paste0('    matrix cb = e(b_',mat,')'),paste0('    matrix cv = e(V_',mat,')'))
            for(j in seq_along(r$tau.hat)) lines <- c(lines,
                sprintf('    capture assert abs(cb[1,%d]-(%s)) <= 1e-8*(1+abs(%s))',j,fmt(r$tau.hat[j]),fmt(r$tau.hat[j])),
                '    if _rc local passed = 0',
                sprintf('    capture assert abs(cv[%d,%d]-(%s)) <= 1e-8*(1+abs(%s))',j,j,fmt(r$se.rob[j]^2),fmt(r$se.rob[j]^2)),
                '    if _rc local passed = 0')
        }
    }
    lines <- c(lines,'}',sprintf('file write report "%d,numerical,`passed\'" _n',call$id))
}
lines <- c(lines,'file close report','file open done using ".build/parity.done", write replace','file write done "complete"','file close done','exit, clear')
writeLines(lines,file.path(root,".build/parity.do"))
write.csv(do.call(rbind,manifest),file.path(root,".build/fixture-manifest.csv"),row.names=FALSE)
cat("Exported",sum(vapply(manifest,function(x)x$status=="exported",logical(1))),"calls.\n")
