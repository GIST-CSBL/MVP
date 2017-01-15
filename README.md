---
output:
  html_document: default
  word_document: default
---
## MVP
### An implementation of Mass spectrometry Data Preprocessor

* MVP is an open-source software for preprocessing mass spectrometry data
* MVP is based on the R language and can be installed easily
* Users can set their own parameters to obtain preprocessed data for various
 situations.
* Duplicate record and missing value problems are alleviated by MVP
* Data preprocessed with MVP can improve the performance of statistical tests

---

### Currently, you can install from GitHub with this command:

```R
devtools::install_github("GIST-CSBL/MVP")
```

We checked installation from Windows, Ubuntu OS.

We will deposit MVP package to CRAN or Bioconductor.  
After submission, we will announce the method to download CRAN or Bioconductor.

---

## Basic usage (Tutorials)

In the package, we previde three example datasets that is reformated.  
Users can access example dataset from this command.

```R
load("data/ToF_Positive_Ion_Cardiovascular_Patient.rda")
load("data/ToF_Negative_Ion_Cardiovascular_Patient.rda")
load("data/Orbitrap_Drug_Treatment.rda")
```

Example data has form like this:

```R
   `Primary ID Source` `Retention time (min)`     Mass `VIP[3]`   CType1     CType2   CType3
                 <chr>                  <dbl>    <dbl>    <dbl>    <dbl>      <dbl>    <dbl>
1          Metabolite1                11.2528 281.2482  40.2478 166.2490 257.803000 147.0570
2          Metabolite2                 9.9003 339.2325  30.8942   0.0000   0.000000   0.0000
3          Metabolite3                11.1987 281.2479  28.0972 166.2490   0.009657 147.0570
4          Metabolite4                10.6036 279.2324  27.1497 145.4630 283.385000 120.6870
5          Metabolite5                 9.9544 339.2323  25.4900   0.0000   1.342160   0.0000
6          Metabolite6                10.4413 327.2323  23.6419  51.8399   0.000000   0.0000
7          Metabolite7                10.4413 327.2325  22.8225  51.8399 147.090000 221.9620
8          Metabolite8                 9.7380 540.3302  16.7910 438.7380 328.657000 405.0670
9          Metabolite9                 5.7346 179.0705  16.3673  35.6990  50.730500  64.3068
10        Metabolite10                10.1708 253.2166  16.1379  17.3362  64.359700  22.4518
# ... with 18,243 more rows, and 174 more variables: CType4 <dbl>, CType5 <dbl>, CType6 <dbl>
```

#### Data format reformating before applying MVP

Each raw MS data has different format. For example, expression of missing value
can be different (0, 1, NaN, ...). 
Also, MVP need to know metadata (num of columns, intensity ratio columns ...)
Thus, before applying MVP, users should execute preparation method below.

```R
reformated_data <- MVP::preprocess_input_data(ToF_Positive_Ion_Cardiovascular_Patient, c(3, 2), c(0.001, 0.3), 0)
```


From data format, we can see identifiers of MS data  
The second and third column shows retention time and m/z ratio respectively  
And from 5th to final column represent intensity signal of each patient.  


For standardize of input raw file, we reformat the raw data like this


---

#### After refining input data, MVP handle dirty data in input file

