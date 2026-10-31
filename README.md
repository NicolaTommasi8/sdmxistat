![StataMin](https://img.shields.io/badge/stata-2015-blue)

# sdmxistat
Nuovo comando Stata per la connessione tramite API SDMX ai dati del portale IstatData di Istat.

Esempi:

    sdmxistat dataflow IT1, clear

    sdmxistat datastructure IT1, dataset(145_361_DF_DCSC_FABBRESID_1_7) clear

    sdmxistat data IT1, clear dataset(143_1043_DF_DCSC_INDPREPROCOSTR_2) dimensions(M.IT.CONS_PRIC_2021.N.)



