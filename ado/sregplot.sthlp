{smcl}
{* *! version 0.1.0 10sep2026}{...}
{title:sregplot — Plot treatment effects and confidence intervals}

{p 8 12 2}
{cmd:sregplot} [{cmd:,} {opt level(#)}
{opt treatmentlabels("label 1" "label 2" ...)}
{opt title(string)} {opt xtitle(string)} {opt ytitle(string)}
{opt cicolor(colorstyle)} {opt msymbol(symbolstyle)} {opt msize(sizestyle)}
{opt mcolor(colorstyle)} {opt mfcolor(colorstyle)} {opt mlwidth(linewidthstyle)}
{opt labcolor(colorstyle)} {opt labsize(sizestyle)} {opt bgcolor(colorstyle)}
{opt nogrid} {opt nozeroline} {opt name(name, replace)}
{opt saving(filename, replace)}]

{p 4 4 2}
Run after {help sreg}, including restored estimates. Draws a horizontal
confidence interval and point estimate for each treatment, annotated with
the estimate and standard error. Intervals are calculated from {cmd:e(b)} and
{cmd:e(V)} using the selected level (default 95). Data and estimation results
are preserved. Labels must be quoted separately and match the number of arms.

{p 4 4 2}
This is the native Stata graphical counterpart of R's {cmd:plot.sreg}; it
returns a Stata graph, not a ggplot object. Stata color/symbol/size styles
replace R aesthetic arguments. The CI color is a single Stata color rather
than an R viridis scale or gradient. The default zero line can be suppressed.

{phang2}{cmd:. sregplot, treatmentlabels("Program A" "Program B") level(90)}{p_end}
{phang2}{cmd:. graph export effects.svg, replace}{p_end}
{phang2}{cmd:. sregplot, cicolor(navy) msymbol(O) nogrid saving(effects.gph, replace)}{p_end}

{p 4 4 2}See {help sreg}, {help graph export}, {help colorstyle}.{p_end}
