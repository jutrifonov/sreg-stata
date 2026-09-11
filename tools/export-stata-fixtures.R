args <- commandArgs(TRUE)
root <- normalizePath(if(length(args)) args[1] else ".")
calls <- readRDS(file.path(root,".build/captured/calls.rds"))
dest <- file.path(root,".build/fixtures")
dir.create(dest,recursive=TRUE,showWarnings=FALSE)
fmt <- function(x) ifelse(is.finite(x),sprintf("%.17g",x),".")
lines <- c('clear all','set more off','set linesize 255','set type double','adopath ++ "ado"',
    'file open report using ".build/parity-results.csv", write replace',
    'file write report "id,kind,passed" _n')
# Record actual numerical discrepancies, independently of pass/fail tolerances.
lines <- c(lines, 'file open numeric using ".build/numerical-values.csv", write replace',
    'file write numeric "id,metric,index,reference,stata" _n')
measurement <- function(id, metric, index, expr, expected) {
    sprintf('    file write numeric "%d,%s,%s,%s," %%24.17g (%s) _n',
            id, metric, index, fmt(expected), expr)
}
dir.create(file.path(root,".build/call-logs"),showWarnings=FALSE)
diagnostics <- list()
manifest <- list()
for(call in calls) {
    x <- call$inputs
    nonnull <- x[c("Y","S","D","G.id","Ng","X")]
    supported <- all(vapply(nonnull,function(v) is.null(v)||is.numeric(v)||is.matrix(v)||is.data.frame(v),logical(1)))
    status <- if(!supported) "R container/type validation; covered by native parser tests" else "exported"
    manifest[[length(manifest)+1]] <- data.frame(id=call$id,file=call$file,test=call$test,test_id=call$test_id,status=status)
    if(!supported) next
    fit <- call$result
    diagnostics[[length(diagnostics)+1L]] <- data.frame(id=call$id,test_id=call$test_id,
        error=if(is.null(call$error)) "" else call$error,
        warnings=paste(call$warnings,collapse="\n"),
        adjusted=if(is.null(fit)) FALSE else !is.null(fit$lin.adj),
        n=if(is.null(fit)) 0 else nrow(fit$data),
        arms=if(is.null(fit)) 0 else length(fit$tau.hat),
        strata=if(is.null(fit)) 0 else length(unique(fit$data$S)),
        clusters=if(is.null(fit)||is.null(fit$data$G.id)) 0 else length(unique(fit$data$G.id)),
        k=if(is.null(fit)||!isTRUE(fit$small.strata)) 0 else {
            data <- if(isTRUE(fit$mixed.design)) fit$res.small$data else fit$data
            sizes <- if(is.null(data$G.id)) table(data$S) else table(unique(data[c("S","G.id")])$S)
            as.integer(sizes[1])
        },
        hc=if(is.null(fit)) FALSE else isTRUE(fit$HC1),
        design=if(is.null(fit)) "" else if(isTRUE(fit$mixed.design)) "mixed design" else if(isTRUE(fit$small.strata)) "small strata" else "large strata",
        covariates=if(is.null(fit)||is.null(fit$lin.adj)) "" else paste(paste0("x",seq_len(ncol(as.data.frame(x$X)))),collapse=" "))
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
        sprintf('quietly log using ".build/call-logs/case-%04d.log", text replace name(diagnostic)',call$id),
        paste('capture noisily',command),'local code = _rc',
        'if `code\' == 0 matrix inference = r(table)',
        'display "__SREG_RC__ `code\'"',
        'quietly log close diagnostic')
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
    for (j in seq_along(fit$tau.hat)) lines <- c(lines,
        measurement(call$id,"estimate",j,sprintf("_b[tau%d]",j),fit$tau.hat[j]),
        measurement(call$id,"se",j,sprintf("_se[tau%d]",j),fit$se.rob[j]))
    # Stata displays z statistics and normal-reference p-values and intervals.
    for(j in seq_along(fit$tau.hat)) for(pair in list(c(3,fit$t.stat[j]),c(4,fit$p.value[j]),c(5,fit$CI.left[j]),c(6,fit$CI.right[j])))
        lines <- c(lines,sprintf('    capture assert abs(inference[%d,%d]-(%s)) <= 1e-8*(1+abs(%s))',pair[1],j,fmt(pair[2]),fmt(pair[2])),
                    '    if _rc local passed = 0')
    for (j in seq_along(fit$tau.hat)) {
        values <- c(z=fit$t.stat[j],p=fit$p.value[j],ci_lower=fit$CI.left[j],ci_upper=fit$CI.right[j])
        for (i in seq_along(values)) lines <- c(lines,
            measurement(call$id,names(values)[i],j,sprintf("inference[%d,%d]",i+2,j),values[i]))
    }
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
        for (i in seq_len(nrow(m))) for (j in seq_len(ncol(m))) lines <- c(lines,
            measurement(call$id,name,paste(i,j,sep=":"),sprintf("sb[%d,%d]",i,j),m[i,j]))
    }
    if(isTRUE(fit$mixed.design)) {
        for (comp in c("small","big")) {
            label <- if(comp=="small") "small" else "large"
            dat <- fit[[paste0("res.",comp)]]$data
            units <- if(is.null(dat$G.id)) nrow(dat) else length(unique(dat$G.id))
            lines <- c(lines,sprintf('    capture assert e(N_%s)==%d',label,units),'    if _rc local passed = 0')
        }
        small_data <- fit$res.small$data; big_data <- fit$res.big$data
        population <- function(d) if(is.null(d$G.id)) nrow(d) else sum(unique(d[c("G.id","Ng")])$Ng)
        share <- population(small_data)/(population(small_data)+population(big_data))
        lines <- c(lines,sprintf('    capture assert abs(e(p_small)-(%s))<1e-12',fmt(share)), '    if _rc local passed = 0')
        for(comp in c("small","big")) {
            mat <- if(comp=="small") "small" else "large"
            r <- fit[[paste0("res.",comp)]]
            lines <- c(lines,paste0('    matrix cb = e(b_',mat,')'),paste0('    matrix cv = e(V_',mat,')'))
            for(j in seq_along(r$tau.hat)) lines <- c(lines,
                sprintf('    capture assert abs(cb[1,%d]-(%s)) <= 1e-8*(1+abs(%s))',j,fmt(r$tau.hat[j]),fmt(r$tau.hat[j])),
                '    if _rc local passed = 0',
                sprintf('    capture assert abs(cv[%d,%d]-(%s)) <= 1e-8*(1+abs(%s))',j,j,fmt(r$se.rob[j]^2),fmt(r$se.rob[j]^2)),
                '    if _rc local passed = 0')
            for(j in seq_along(r$tau.hat)) lines <- c(lines,
                measurement(call$id,paste0("estimate_",mat),j,sprintf("cb[1,%d]",j),r$tau.hat[j]),
                measurement(call$id,paste0("variance_",mat),j,sprintf("cv[%d,%d]",j,j),r$se.rob[j]^2))
        }
    }
    lines <- c(lines,'}',sprintf('file write report "%d,numerical,`passed\'" _n',call$id))
}
lines <- c(lines,'file close numeric','file close report','file open done using ".build/parity.done", write replace','file write done "complete"','file close done','exit, clear')
writeLines(lines,file.path(root,".build/parity.do"))
write.csv(do.call(rbind,manifest),file.path(root,".build/fixture-manifest.csv"),row.names=FALSE)
cat("Exported",sum(vapply(manifest,function(x)x$status=="exported",logical(1))),"calls.\n")

write.csv(do.call(rbind,diagnostics),file.path(root,".build/diagnostic-expectations.csv"),row.names=FALSE)
