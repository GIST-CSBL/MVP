## MVP
### An implementation of Mass spectrometry Data Preprocessor

* 
MVP is an open-source software for preprocessing mass spectrometry data.
* 
MVP is based on the R language and can be installed easily.
* 
Users can set their own parameters to obtain preprocessed data for various situations.
* 
Duplicate record and missing value problems are alleviated by MVP.
* 
Data preprocessed with MVP can improve the performance of statistical tests.

---

### Currently, you can install:

* the latest development version from GitHub with

```R
devtools::install_github("GIST-CSBL/MVP")
```

We checked installation from Windows, Ubuntu OS.

We will deposit MVP package to CRAN or Bioconductor.  
After submission, we will announce the method to download CRAN or Bioconductor.

---

## Basic usage (Tutorials)

MVP process is composed of two steps:

* First step is refining input data for using MVP software

  > Standardize file format, expression of missing value (0, 1, ...) to NA
  
  > Save and tell metadata to MVP
  
Code example is like this:

```R
      Primary ID Source Retention time (min)      Mass   VIP[2]  DS1.P_C14 DS1.P_C15 DS1.P_C20 DS1.P_C24 DS1.P_C35
   1:     2.10_413.2665              11.3610  413.2665 75.65660   0.000000 801.22500  658.9790 829.51200 850.96200
   2:     2.10_803.5420              11.3610  803.5420 52.90680   0.000000 385.30700  287.1710 461.28300 443.44500
   3:     2.09_413.2666              11.3069  413.2666 50.47040 638.850000   1.94153  658.9790   1.80367   4.71944
   4:     2.09_803.5420              11.3069  803.5420 34.93750 277.134000   0.00000  287.1710   0.00000   0.00000
   5:     1.97_379.2823              10.6577  379.2823 31.49450   5.820570  49.79090    2.2531  45.17050   7.39718
```

```R
reformated_data <- MVP::preprocess_input_data("foo/bar.tsv", )
```
  
* After refining input data, MVP handle dirty data in input file
