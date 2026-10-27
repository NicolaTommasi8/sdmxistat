{smcl}
{* *! version 1.0  Sep 2026}{...}
{viewerjumpto "Title" "sdmxistat##title"}{...}
{viewerjumpto "Syntax" "sdmxistat##syntax"}{...}
{viewerjumpto "Description" "sdmxistat##description"}{...}
{viewerjumpto "Options" "sdmxistat##options"}{...}
{viewerjumpto "Examples" "sdmxistat##examples"}{...}
{viewerjumpto "Remarks" "sdmxistat##remarks"}{...}
{viewerjumpto "Reference" "sdmxistat##ref"}{...}
{viewerjumpto "Author" "sdmxistat##author"}{...}
{viewerjumpto "Also see" "sdmxistat##alsosee"}{...}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:sdmxistat}:}Import data from IstatData website using the SDMX standard{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 8 2}
{cmdab:sdmxistat} {cmd:dataflow} {it:provider} [{cmd:, clear}]

{p 8 8 2}
{cmdab:sdmxistat} {cmd:datastructure} {it:provider}{cmd:,} {cmd:dataset(}{it:identifier}{cmd:)} [{cmd:clear}]

{p 8 8 2}
{cmdab:sdmxistat} {cmd:data} {it:provider}{cmd:,} {cmd:dataset(}{it:identifier}{cmd:)} [{it:options}]

{pstd}
Available {it:provider}s:{break}
- ISTAT ({cmd:IT1}){break}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {cmd:dataset(}{it:identifier}{cmd:)}}specify the dataset{p_end}
{synopt:{bf:clear}}clear data in memory{p_end}
{synopt:{opt dimensions(string)}}allow customizing requests for data{p_end}
{synopt:{bf:attributes}}download attributes (for example, observations' flags){p_end}
{synopt:{opt start(string)}}define start period{p_end}
{synopt:{opt end(string)}}define end period{p_end}
{synopt:{bf:timeseries}}reshape dataset to obtain time series{p_end}
{synopt:{opt panel(panelvar)}}reshape dataset to obtain a panel{p_end}
{synopt:{bf:mergedsd}}merge data (time series) and data structure definition (DSD){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:dataset(}{it:identifier}{cmd:)} is required for
{cmd:sdmxistat datastructure} and {cmd:sdmxistat data}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:sdmxistat} imports data from statistical agencies using the SDMX standard.

{pstd}
You can get a complete list of publicly available datasets from a provider by
specifying the resource {cmd:dataflow}.  Then, you can obtain the DSD of a
given dataset by specifying the resource: {cmd:datastructure}.  Finally, you
can download the dataset by specifying the resource: {cmd:data}.


{marker options}{...}
{title:Options}

{phang}
{opt dataset(identifier)} can be found by first downloading {cmd:dataflow}.
You can also find the dataset identifier on some providers' websites.
ISTAT, for instance, refers to the dataset identifier as "id dataflow"
{browse "https://esploradati.istat.it/databrowser/"}.  Users should realize
that datasets' identifiers are case sensitive and may contain underscores or
other symbols.  The option {cmd:dataset()} is required for
{cmd:sdmxistat datastructure} and {cmd:sdmxistat data}.

{phang}
{opt clear} specifies that data in memory be replaced with the imported
data.

{phang}
{opt dimensions(string)} allows one to customize requests for data.  Time
series can be retrieved based on the value they take for each dimension.
Dimensions should be separated by a dot ({cmd:.}) character and must respect
the order specified in the DSD.  A dimension can be left empty if all values
are requested.  Multiple values for a dimension are separated by a plus
({cmd:+}) sign.

{phang}
{opt attributes} downloads attributes that give additional information about
the series or the observations but do not affect the dataset structure itself
(for example, observations' flags). (NOT BEEN TESTED!!)

{phang}
{opt start(string)} defines the start period.  You can specify the exact value
(for example, {cmd:2010-01}) or just the year (for example, {cmd:2010}).

{phang}
{opt end(string)} defines the end period.

{phang}
{opt timeseries} reshapes the dataset so that each series is stored in a
single variable.  Variables' names are made of the values of the series for
each dimension. (NOT BEEN TESTED!!)

{phang}
{opt panel(panelvar)} reshapes the dataset into a panel.  {it:panelvar} will
often be the geographical dimension. (NOT BEEN TESTED!!)

{phang}
{opt mergedsd} merges the data (time series) and the DSD -- particularly
useful when dimensions' codes are not transparent (for example, {cmd:HRV} is
the International Organization for Standardization alpha-3 code for Croatia).


{marker examples}{...}
{title:Examples}

{phang}
{cmd:. sdmxistat dataflow IT1, clear}{p_end}

{phang}
{cmd:. sdmxistat datastructure IT1, clear dataset(114_191_DF_DCSC_ORDFATT_9)}{p_end}

{phang}
{cmd:. sdmxistat data IT1, clear dataset(DF_DCSS_FAM_POP_TV_1) dimensions(A..NPHH_AV+POPHH_AV+RESPOP_AV) start(2022-01-01) end(2024-12-31) mergedsd}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
The author is grateful to Robert Picard and Nicholas J. Cox (2011) for
allowing him to reproduce their code of the package {cmd:moss} to deal with
multiple occurrences of substrings ({cmd:moss} automatically installed by {cmd:smxuse2}).



{marker ref}{...}
{title:Reference}

{phang}
Picard, R., and N. J. Cox. 2011. moss: Stata module to find multiple occurrences
of substrings. Statistical Software Components S457261, Department of
Economics, Boston College.
{browse "https://ideas.repec.org/c/boc/bocode/s457261.html"}.


{marker author}{...}
{title:Author}

{pstd}
S{c e'}bastien Fontenay{break}
Universit{c e'} catholique de Louvain{break}
Louvain-la-Neuve, Belgium{break}
sebastien.fontenay@uclouvain.be{p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 18, number 4: {browse "http://www.stata-journal.com/article.html?article=dm0097":dm0097}{p_end}
