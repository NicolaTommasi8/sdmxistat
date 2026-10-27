**v 1.0 07sep2026: -aggiunte label in italiano (*_it)
**                 -sistemato encoding dei caratteri accentati


/*******************************************************************************
  Author: Sebastien Fontenay (sebastien.fontenay@uclouvain.be)
  Version: 2.0
  Last update: June 2018

  This program uses the package "moss" by Robert Picard & Nicholas J. Cox

  Many thanks for suggestions of improvements to: Samuel Pinto Ribeiro & Jan Helmdag
  Modified by myself

 see sdmxpdh

sdmxistat is a version of the SDMXUSE Stata module, with the changes
 allowing users to connect to ISTAT.

Full credit goes to Sebastien Fontenay, Robert Picard, Nicholas Cox.

This module is a simple adaptation of the SDMXUSE module (Fontenay),
 which itself uses the MOSS module (Picard & Cox).

Sebastien Fontenay, 2016. "SDMXUSE: Stata module to import data from statistical agencies using the SDMX standard"
 Statistical Software Components S458231, Boston College Department of Economics, revised 30 Sep 2018.

Robert Picard & Nicholas J. Cox, 2011. "MOSS: Stata module to find multiple occurrences of substrings"
 Statistical Software Components S457261, Boston College Department of Economics, revised 29 Apr 2016.

see:
https://esploradati.istat.it/databrowser/#/it
https://datiistat.it/alldataflows
*******************************************************************************/

program define sdmxistat, rclass
version 17.0
syntax namelist(min=2 max=2) [, clear dataset(string) dimensions(string) attributes start(string) end(string) timeseries panel(string) mergedsd]

capture which moss
if _rc==111 {
  di in yellow "moss not installed.... installing..."
  ssc inst moss
}


**# Create local macros
tokenize `namelist'
local resource "`1'"
local provider "`2'"

if "`provider'"=="IT1" {
  local url "https://esploradati.istat.it/SDMXWS/rest/"
  local prefix="generic:"
  local prefix_str="structure:"
  local prefix_com="common:"
  local dataflow="<`prefix_str'Dataflow "
  local id="id"
  local name="common:Name"
  local value_id="<`prefix'Value id="
  if "`start'"!="" local start "&startPeriod=`start'"
  if "`end'"!="" local end "&endPeriod=`end'"
}

// Rename macro (differs according to OS)
if c(os)=="Windows" local renamecmd "!rename"
else local renamecmd "!mv"

// Error message
if ("`resource'"=="datastructure" & "`dataset'"=="") | ("`resource'"=="data" & "`dataset'"=="") {
  noisily display in red "You must specify the dataset identifier with the following option [, dataset()]"
  exit
}
if ("`timeseries'"!="" & "`mergedsd'"!="") | ("`panel'"!="" & "`mergedsd'"!="") {
  noisily display in red "You cannot specify both timeseries/panel and mergedsd options"
  exit
}

// Clear data
if `"`clear'"' == "clear" clear
if (c(changed) == 1) & (`"`clear'"' == "" ) error 4

**#Dataflow

if "`resource'"=="dataflow" {
  **## Build and send query
  di "Build and send query..."
  qui copy "`url'dataflow/`provider'/" tmp_sdmxdataflow.txt, replace

**## Import data into Stata
  di "Import data into Stata..."
  qui {
  filefilter tmp_sdmxdataflow.txt tmp_sdmxdataflow2.txt, from("\n") to ("") replace
  erase tmp_sdmxdataflow.txt
  `renamecmd' tmp_sdmxdataflow2.txt tmp_sdmxdataflow.txt
  filefilter tmp_sdmxdataflow.txt tmp_sdmxdataflow2.txt, from("\r") to ("") replace
  erase tmp_sdmxdataflow.txt
  `renamecmd' tmp_sdmxdataflow2.txt tmp_sdmxdataflow.txt
  filefilter tmp_sdmxdataflow.txt tmp_sdmxdataflow2.txt, from("`dataflow'") to ("\r\n`dataflow'") replace
  erase tmp_sdmxdataflow.txt
  `renamecmd' tmp_sdmxdataflow2.txt tmp_sdmxdataflow.txt
  import delimited tmp_sdmxdataflow.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)
  }

**## Format dataset
  di "Format Dataset..."
  moss v1, match(`"<`prefix_com'Name xml:lang="en">(.*)</`prefix_com'Name>"') regex
  rename _match1 dataflow_description
  qui replace dataflow_description=substr(dataflow_description, 1, strpos(dataflow_description, "</`prefix_com'Name>")-1) if strmatch(dataflow_description,"*</`prefix_com'Name>*")
  drop _*
  moss v1, match(`"<`prefix_com'Name xml:lang="it">(.*)</`prefix_com'Name>"') regex
  rename _match1 dataflow_description_it
  qui replace dataflow_description_it=substr(dataflow_description_it, 1, strpos(dataflow_description_it, "</`prefix_com'Name>")-1) if strmatch(dataflow_description_it,"*</`prefix_com'Name>*")
  drop _*

  moss v1, match(`"<`prefix_com'AnnotationText xml:lang="en">(.*)</`prefix_com'AnnotationText>"') regex
  rename _match1 annot_en
  qui replace annot_en=substr(annot_en, 1, strpos(annot_en, "</`prefix_com'AnnotationText>")-1) if strmatch(annot_en,"*</`prefix_com'AnnotationText>*")
  qui replace annot_en="" if strmatch(annot_en,"http*") | annot_en=="true"
  drop _*
  moss v1, match(`"<`prefix_com'AnnotationText xml:lang="it">(.*)</`prefix_com'AnnotationText>"') regex
  rename _match1 annot_it
  qui replace annot_it=substr(annot_it, 1, strpos(annot_it, "</`prefix_com'AnnotationText>")-1) if strmatch(annot_it,"*</`prefix_com'AnnotationText>*")
  qui replace annot_it="" if strmatch(annot_it,"http*") | annot_it=="true"
  drop _*

  local strsize=strlen("</`prefix_com'Name>")-1
  qui replace v1=substr(v1, 1, strpos(v1, "</`prefix_com'Name>")+`strsize')
  moss v1, match(`"id="([a-zA-Z0-9_-]+)"') regex
  rename _match1 dataflow_id
  drop _*
  **! dato che non sempre la descrizione in prima posizione è quella inglese, bisogna spostarla prima (vedi sopra)
  **moss v1, match(`"<`prefix_com'Name xml:lang="en">(.*)</`prefix_com'Name>"') regex
  **rename _match1 dataflow_description

  qui {
  gen v2 = substr(v1,strpos(v1, `"<common:Annotation id="LAST_UPDATE">"')-37,.)
  gen last_update = ustrregexs(1) if ustrregexm(v2, "([0-9]{4}-[0-9]{2}-[0-9]{2})")
  gen temp = ustrregexs(1) if ustrregexm(v2, "([0-9]{2}/[0-9]{2}/[0-9]{4})")
  replace last_update = substr(temp,-4,.) + "-" + substr(temp,1,2) + "-" + substr(temp,4,2) if last_update=="" & temp!=""
  }
  drop temp
  drop v1 v2
  order dataflow_id dataflow_description
  qui drop if dataflow_id==""
  sort dataflow_id, stable
  qui compress
  cap erase tmp_sdmxdataflow.txt
}



**#Datastructure
if "`resource'"=="datastructure" | "`mergedsd'"!="" {
**## Find datastructure_id
  if "`resource'"=="datastructure" di "Find datastructure..."
  qui copy "`url'dataflow/`provider'/`dataset'/" tmp_sdmxdataflow.txt, replace
  filefilter tmp_sdmxdataflow.txt tmp_sdmxdataflow2.txt, from("\n") to ("") replace
  erase tmp_sdmxdataflow.txt
  `renamecmd' tmp_sdmxdataflow2.txt tmp_sdmxdataflow.txt
  filefilter tmp_sdmxdataflow.txt tmp_sdmxdataflow2.txt, from("\r") to ("") replace
  erase tmp_sdmxdataflow.txt
  `renamecmd' tmp_sdmxdataflow2.txt tmp_sdmxdataflow.txt
  qui import delimited tmp_sdmxdataflow.txt, clear delimiters("|||", asstring) varnames(nonames) encoding(UTF-8)
    qui replace v1=substr(v1, strpos(v1, "<`prefix_str'Structure>"), .)
  moss v1, match(`"id="([a-zA-Z0-9_-]+)"') regex
  rename _match1 datastructure_id
  drop _* v1
  local datasetDSD=datastructure_id[1]
  cap erase tmp_sdmxdataflow.txt

**## Build and send query
  if "`resource'"=="datastructure" di "Build and send query..."
  qui copy "`url'datastructure/`provider'/`datasetDSD'/?references=children" tmp_sdmxdatastructure.txt, replace

**## Import data into Stata
  if "`resource'"=="datastructure" di "Import data into Stata..."
  filefilter tmp_sdmxdatastructure.txt tmp_sdmxdatastructure2.txt, from("\n") to ("") replace
  erase tmp_sdmxdatastructure.txt
  `renamecmd' tmp_sdmxdatastructure2.txt tmp_sdmxdatastructure.txt
  filefilter tmp_sdmxdatastructure.txt tmp_sdmxdatastructure2.txt, from("\r") to ("") replace
  erase tmp_sdmxdatastructure.txt
  `renamecmd' tmp_sdmxdatastructure2.txt tmp_sdmxdatastructure.txt
  qui copy tmp_sdmxdatastructure.txt codelists.txt, replace

**## Data structure
  if "`resource'"=="datastructure" di "Create Data Structure..."
  filefilter tmp_sdmxdatastructure.txt tmp_sdmxdatastructure2.txt, from("<`prefix_str'Dimension ") to ("\r\n<`prefix_str'Dimension ") replace
  erase tmp_sdmxdatastructure.txt
  `renamecmd' tmp_sdmxdatastructure2.txt tmp_sdmxdatastructure.txt
  qui import delimited tmp_sdmxdatastructure.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames) encoding(UTF-8)

  tempfile dimensionsDSD
  local strsize=strlen("</`prefix_str'Dimension>")-1
  qui replace v1=substr(v1, 1, strpos(v1, "</`prefix_str'Dimension>")+`strsize')
  moss v1, match(`"id="([a-zA-Z0-9_-]+)"') regex
  rename _match1 concept
  rename _match3 codelist
  qui replace codelist=subinstr(codelist, "CL_", "", .)
  drop _*
  moss v1, match(`"position="([0-9]+)"') regex
  rename _match1 position
  qui destring position, replace
  drop _*
  sort position
  drop v1
  local _concept ""
  qui count
  forvalues i=1/`r(N)' {
    if `i'!=`r(N)' local _concept="`_concept'"+concept[`i']+"."
    if `i'==`r(N)' local _concept="`_concept'"+concept[`i']
  }
  if "`mergedsd'"=="" noisily di "Order of dimensions: (`_concept')"

  qui sum position
  local position_nb=r(N)
  qui save `dimensionsDSD', replace

  // Codelists
  filefilter codelists.txt codelists2.txt, from("<`prefix_str'Codelist ") to ("\r\n<`prefix_str'Codelist ") replace
  erase codelists.txt
  `renamecmd' codelists2.txt codelists.txt
  filefilter codelists.txt codelists2.txt, from("<`prefix_str'Code ") to ("\r\n<`prefix_str'Code ") replace
  erase codelists.txt
  `renamecmd' codelists2.txt codelists.txt
  qui import delimited codelists.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames) encoding(UTF-8)

  // Format dataset
  local strsize=strlen("</`prefix_str'Code>")-1
  qui replace v1=substr(v1, 1, strpos(v1, "</`prefix_str'Code>")+`strsize') if regexm(v1, "</`prefix_str'Code>")
  qui gen series=regexm(v1, "<`prefix_str'Codelist ")
  qui replace series=sum(series)

  preserve
    tempfile concept
    qui keep if regexm(v1, "<`prefix_str'Codelist ")
    moss v1, match(`"id="CL_([a-zA-Z0-9_-]+)"') regex
    rename _match1 concept
    drop _* v1
    qui save `concept', replace
  restore

  tempfile codes
  qui keep if regexm(v1, "<`prefix_str'Code ")
  moss v1, match(`"`id'="([a-zA-Z0-9_-]+)"') regex max(1)
  rename _match1 code
  drop _*
  moss v1, match(`"<`name' xml:lang="en">(.*)</`name'>"') regex
  rename _match1 code_lbl
  drop _* /*v1*/
  qui replace code_lbl=substr(code_lbl, 1, strpos(code_lbl, "</`prefix_com'Name>")-1) if strmatch(code_lbl,"*</`prefix_com'Name>*")

  moss v1, match(`"<`name' xml:lang="it">(.*)</`name'>"') regex
  rename _match1 code_lbl_it
  drop _* v1
  qui replace code_lbl_it=substr(code_lbl_it, 1, strpos(code_lbl_it, "</`prefix_com'Name>")-1) if strmatch(code_lbl_it,"*</`prefix_com'Name>*")
  qui save `codes', replace

  qui use `concept', clear
  qui merge 1:m series using `codes', nogenerate
  drop series
  rename concept codelist
  qui save `concept', replace

  forvalues i=1/`position_nb' {
    qui use `dimensionsDSD' if position==`i', clear
    qui merge 1:m codelist using `concept', nogenerate keep(3)
    tempfile dim`i'
    qui save `dim`i'', replace
  }
  qui use `dim1', clear
  forvalues i=2/`position_nb' {
    append using `dim`i''
  }
  qui replace codelist=concept if codelist!=concept & concept!=""
  drop concept
  rename codelist concept
  order position, after(concept)
  sort position concept code

  // Erase text file with raw data
  cap erase tmp_sdmxdatastructure.txt
  cap erase codelists.txt

**## Save DSD to merge with data
  if "`mergedsd'"!="" {
    qui levelsof concept, clean
    local concepts_list="`r(levels)'"
    foreach concept of local concepts_list {
      preserve
        qui keep if concept=="`concept'"
        keep code code_lbl* /*include it code*/
        local concept2=strlower("`concept'")
        rename code* `concept2'*
        qui compress
        tempfile dsd_`concept2'
        qui save `dsd_`concept2'', replace
      restore
    }
  }

  if "`resource'"=="datastructure" {
    di "Frequencies of Dimensions"
    preserve
      contract position concept
      rename _freq dimensions
      qui tostring dimensions , replace
      format dimensions %15s
      qui replace dimensions = "      "+dimensions
      list position concept dimensions, sep(0) noobs
    restore
  }
  qui compress
}


**# Data
if "`resource'"=="data" {
**## Build and send query
  di "Build and send query"
  local detail "dataonly"
  if "`attributes'"!="" local detail "full"
  if "`dimensions'"!="" local dimensions "/`dimensions'"
  local call "`url'data/IT1,`dataset',1.0`dimensions'/?detail=`detail'`start'`end'"
  global call "`url'data/IT1,`dataset',1.0`dimensions'/&detail=`detail'`start'`end'"
  di "QUERY: `call'"
  qui copy "`url'data/IT1,`dataset',1.0`dimensions'/?detail=`detail'`start'`end'" tmp_sdmxfile.txt, replace

**## Import data (generic format) into Stata
  di "Import data into Stata..."
  filefilter tmp_sdmxfile.txt tmp_sdmxfile2.txt, from("\n") to ("") replace
  erase tmp_sdmxfile.txt
  `renamecmd' tmp_sdmxfile2.txt tmp_sdmxfile.txt
  filefilter tmp_sdmxfile.txt tmp_sdmxfile2.txt, from("\r") to ("") replace
  erase tmp_sdmxfile.txt
  `renamecmd' tmp_sdmxfile2.txt tmp_sdmxfile.txt
  filefilter tmp_sdmxfile.txt tmp_sdmxfile2.txt, from("<`prefix'Obs>") to ("\r\n<`prefix'Obs>") replace
  erase tmp_sdmxfile.txt
  `renamecmd' tmp_sdmxfile2.txt tmp_sdmxfile.txt
  filefilter tmp_sdmxfile.txt tmp_sdmxfile2.txt, from("<`prefix'Series>") to ("\r\n<`prefix'Series>") replace
  erase tmp_sdmxfile.txt
  `renamecmd' tmp_sdmxfile2.txt tmp_sdmxfile.txt
  qui import delimited tmp_sdmxfile.txt, clear delimiters("|||", asstring) rowrange(2) varnames(nonames)  encoding(UTF-8)
  qui count
  if r(N)==0  {
    noisily display in red "The query did not match any time series - check again the dimensions' values or download the full dataset"
    cap erase tmp_sdmxfile.txt
    exit
  }

**## Format dataset
  di "Formatting dataset...""
  tempfile data
  qui gen series=regexm(v1, "SeriesKey")
  qui replace series=sum(series)
  qui sum series
  noisily display in green "`r(max)' serie(s) imported"
  qui count
  preserve
    qui drop if !regexm(v1, "Obs")

    **### Time
    local strsize=strlen("<`prefix'ObsDimension id=")+1
    qui gen time=substr(substr(substr(v1, strpos(v1, "<`prefix'ObsDimension id=")+`strsize', .), 1, strpos(substr(v1, strpos(v1, "<`prefix'ObsDimension id=")+`strsize', .), `"/>"')-3), ///
                 strpos(substr(substr(v1, strpos(v1, "<`prefix'ObsDimension id=")+`strsize', .), 1, strpos(substr(v1, strpos(v1, "<`prefix'ObsDimension id=")+`strsize', .), `"/>"')-3), "value=")+7, .)

    **### Values
    local strsize=strlen("<`prefix'ObsValue value=")+1
    qui gen value=substr(substr(v1, strpos(v1, "<`prefix'ObsValue value=")+`strsize', .), 1, strpos(substr(v1, strpos(v1, "<`prefix'ObsValue value=")+`strsize', .), `"""')-1)
    qui replace value="" if value=="NaN"
    qui destring value, replace
    char value[destring]
    char value[destring_cmd]

    **### Attributes
    if "`attributes'"!="" {
      tempvar Attributes
      local strsize=strlen("<`prefix'Attributes>")
      qui gen `Attributes'=substr(substr(v1, strpos(v1, "<`prefix'Attributes>")+`strsize',.), 1, strpos(substr(v1, strpos(v1, "<`prefix'Attributes>")+`strsize',.), "</`prefix'Attributes>")-1)
      capture assert missing(`Attributes')
      if _rc {
        moss `Attributes', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
        qui sum _count
        local macroconcept ""
        forvalues i=1/`r(max)' {
          qui levelsof _match`i', clean
          local macroconcept="`macroconcept' `r(levels)'"
        }
        local macroconceptuniq : list uniq macroconcept
        foreach var of local macroconceptuniq {
          qui gen `var'=substr(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), strpos(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), "value=")+7, ///
                         strpos(substr(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), strpos(substr(`Attributes', strpos(`Attributes', `""`var'""'), .), "value=")+7, .), `"""')-1)
        }
        drop _*
      }
    }
    drop v1
    qui save `data', replace
  restore
  qui drop if regexm(v1, "Obs")

  **### Values
  tempvar SeriesKey
  local strsize=strlen("<`prefix'SeriesKey>")
  qui gen `SeriesKey'=substr(substr(v1, strpos(v1, "<`prefix'SeriesKey>")+`strsize',.), 1, strpos(substr(v1, strpos(v1, "<`prefix'SeriesKey>")+`strsize',.), "</`prefix'SeriesKey>")-1)
  moss `SeriesKey', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
  qui sum _count
  local macroconcept ""
  forvalues i=1/`r(max)' {
    qui levelsof _match`i', clean
    local macroconcept="`macroconcept' `r(levels)'"
  }
  local macroconceptuniq : list uniq macroconcept
  foreach var of local macroconceptuniq {
    qui gen `var'=substr(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), strpos(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), "value=")+7, ///
                   strpos(substr(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), strpos(substr(`SeriesKey', strpos(`SeriesKey', `""`var'""'), .), "value=")+7, .), `"""')-1)
  }
  drop _*


  **### Create variable serieskey if dataset needs to be reshaped
  if "`timeseries'"!="" {
    foreach var of varlist `macroconceptuniq' {
      bysort `var': qui gen nvals = _n == 1
      qui replace nvals = sum(nvals)
      if nvals[_N]==1 {
        local macroconceptuniq : subinstr local macroconceptuniq "`var'" ""
      }
      drop nvals
    }
    local blank : subinstr local macroconceptuniq " " "", all
    if "`blank'"!="" {
      qui egen serieskey=concat(`macroconceptuniq'), punct("_")
      qui replace serieskey=lower(serieskey)
      qui replace serieskey=subinstr(serieskey, "-", "_", .)
      order serieskey
      qui gen length=strlen(serieskey)
      qui sum length
      local maxlength=r(max)
      if `maxlength'>32 {
        drop serieskey length
        qui gen serieskey=series
        qui tostring serieskey, replace
      }
    }
  }
  if "`panel'"!="" {
    capture confirm variable `panel'
    if _rc {
      local panel=strupper("`panel'")
      capture confirm variable `panel'
      if _rc {
        noisily di in red "Variable `panel' not found"
        cap erase tmp_sdmxfile.txt
        exit
      }
    }
    local nogeo : subinstr local macroconceptuniq "`panel'" ""
    foreach var of varlist `nogeo' {
      bysort `var': qui gen nvals = _n == 1
      qui replace nvals = sum(nvals)
      if nvals[_N]==1 {
        local nogeo : subinstr local nogeo "`var'" ""
      }
      drop nvals
    }
    local blank : subinstr local nogeo " " "", all
    if "`blank'"!="" {
      qui egen serieskey=concat(`nogeo'),  maxlength(32) punct("_")
      qui replace serieskey=lower(serieskey)
      qui replace serieskey=subinstr(serieskey, "-", "_", .)
      order serieskey
      qui gen length=strlen(serieskey)
      qui sum length
      local maxlength=r(max)
      if `maxlength'>32 {
        drop serieskey length
        qui gen serieskey=series
        qui tostring serieskey, replace
      }
    }
    local panel=strlower("`panel'")
  }

  if "`attributes'"=="" drop v1

  **### Attributes
  if "`attributes'"!="" {
    tempvar Attributes2
    local strsize=strlen("<`prefix'Attributes>")
    qui gen `Attributes2'=substr(substr(v1, strpos(v1, "<`prefix'Attributes>")+`strsize',.), 1, strpos(substr(v1, strpos(v1, "<`prefix'Attributes>")+`strsize',.), "</`prefix'Attributes>")-1)
    capture assert missing(`Attributes2')
    if _rc {
      moss `Attributes2', match(`"`value_id'"([a-zA-Z0-9_]+)""') regex
      qui sum _count
      local macroconcept ""
      forvalues i=1/`r(max)' {
        qui levelsof _match`i', clean
        local macroconcept="`macroconcept' `r(levels)'"
      }
      local macroconceptuniq : list uniq macroconcept
      foreach var of local macroconceptuniq {
        qui gen `var'=substr(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), strpos(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), "value=")+7, strpos(substr(substr(`Attributes2', ///
                             strpos(`Attributes2', `""`var'""'), .), strpos(substr(`Attributes2', strpos(`Attributes2', `""`var'""'), .), "value=")+7, .), `"""')-1)
      }
      drop _*
    }
    drop v1
  }

  **### Merge data and dimensions' identifiers
  qui merge 1:m series using `data', nogenerate
  sort series, stable
  drop series
  rename _all, lower

  **### Merge with DSD
  if "`mergedsd'"!="" {
    qui ds time value, not
    local varlist="`r(varlist)'"
    foreach var of local varlist {
      qui merge m:1 `var' using `dsd_`var'', nogenerate keep(1 3)
      order `var'_lbl, after(`var')
    }
    qui compress
  }

  **### Reshape dataset
  if "`timeseries'"!="" {
    if "`blank'"!="" {
      keep serieskey time value
      qui reshape wide value, i(time) j(serieskey, string)
      if `maxlength'>32 {
        order time value*, sequential
      }
      qui cap rename value* *
    }
    sort time
  }

  if "`panel'"!="" {
    if "`blank'"!="" {
      keep serieskey time value `panel'
      qui reshape wide value, i(time `panel') j(serieskey, string)
      if `maxlength'>32 order `panel' time value*, sequential
      qui cap rename value* *
    }
    sort `panel' time
  }

  cap erase tmp_sdmxfile.txt
}


return local CALL = "`call'"
end

