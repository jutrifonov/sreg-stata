{smcl}
{title:sreg_aejapp — Peru iron supplementation example data}

{p 4 4 2}
This is the complete AEJapp dataset bundled with the R sreg package:
215 observations and 62 original variables. Variable names, values, missing
values and observation order are preserved in Stata format.

{title:Download and load the included data}
{phang2}{cmd:. net get sreg, from("/path/to/sreg-stata") replace}{p_end}
{phang2}{cmd:. use sreg_aejapp.dta, clear}{p_end}

{p 4 4 2}Replace the path with the downloaded package folder. {cmd:net get}
places the example dataset in the current working directory.

{title:Replicate the R example}
{phang2}{cmd:. generate byte D = cond(treatment == 3, 0, treatment)}{p_end}
{phang2}{cmd:. sreg gradesq34, treatment(D) strata(class_level)}{p_end}
{phang2}{cmd:. sreg gradesq34 pills_taken age_months, treatment(D) strata(class_level)}{p_end}

{p 4 4 2}
The outcome is gradesq34, strata are class_level, and treatment code 3
is recoded to control (0). The second specification uses pills_taken and
age_months, matching the R README. The original variables remain unchanged.

{title:Source and citation}
{p 4 4 2}
Chong, A., Cohen, I., Field, E., Nakasone, E., and Torero, M. (2016).
Iron Deficiency and Schooling Attainment in Peru.
American Economic Journal: Applied Economics 8(4): 222–255.
{browse "https://doi.org/10.1257/app.20140494":doi:10.1257/app.20140494}.

{p 4 4 2}
Replication data distributed by the American Economic Association and ICPSR:
{browse "https://doi.org/10.3886/E113624V1":doi:10.3886/E113624V1}.
This Stata copy is converted from data/AEJapp.rda in
{browse "https://github.com/jutrifonov/sreg":the R sreg repository}.

{p 4 4 2}
See examples/try_sreg.do in the Stata repository for the complete walkthrough.
