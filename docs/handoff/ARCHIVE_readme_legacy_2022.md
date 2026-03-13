# Archived Legacy README (2022 Narrative)

This file preserves the historical README content for reference only. It is not the current operating procedure. Use `README.md` and files in `docs/handoff/` for active workflow instructions.

---

LACN 2022 Survey
================

This document walks you through the structure, purpose, and output of
this repository. All scripts can be found in the **code** directory.

## 2025-26 Cycle Quick Run

The repo now supports cycle-based local runs (no Google Sheets dependency in the
core pipeline). For the 2025-26 cycle:

1.  Ensure your local dependencies are installed in R (tidyverse, rmarkdown,
    showtext, gt, ggrepel, etc.).
2.  Run the full pipeline:

``` bash
Rscript code/run_cycle.R --cycle=26
```

This command will:

- ingest `data/OpsSurveyRawData2.27.26.csv`
- validate schema and write `data/schema_check_26.csv`
- regenerate `lacn.RData`
- render `docs/GeneralReport.html`
- render all school reports to `docs/custom/*.html`
- render `docs/index.html`

## Fork/Publish Workflow

Set your fork as `origin` and keep the original repository as `upstream`:

``` bash
git remote rename origin upstream
git remote add origin <your-fork-url>
git remote -v
```

Then publish:

``` bash
git add .
git commit -m "2025-26 cycle report refresh"
git push origin main
```

In GitHub Pages settings, use branch `main` and folder `/docs`.

# File Structure

    ## Contents of lacn directory

    ##  [1] "_site.yml"          "code"               "data"              
    ##  [4] "docs"               "images"             "index.Rmd"         
    ##  [7] "lacn-benchmark.csv" "lacn-benchmark.R"   "lacn.RData"        
    ## [10] "lacn.Rproj"         "README.md"          "README.Rmd"

    ## 
    ## Files in code subdirectory

    ##  [1] "1_read_data.R"             "2_clean.R"                
    ##  [3] "3_functions.R"             "4_viz_intro.R"            
    ##  [5] "5_viz_reporting.R"         "6_viz_services.R"         
    ##  [7] "7_viz_employer.R"          "8_viz_engagement.R"       
    ##  [9] "9_viz_budget.R"            "99_custom_exe.R"          
    ## [11] "99_email_sharing.R"        "99_processing_functions.R"
    ## [13] "99_processing.R"           "source.R"

    ## 
    ## Files in data subdirectory

    ## [1] "OpsSurveyRawData4.14.22.csv" "response_key.csv"

# Load Data

Script: **1\_read\_data.R**

The raw survey data (“lacn\_2022.csv”) resides in the data subdirectory
of the lacn folder. The first several lines of this script load this
data and remove several redundant rows, as well as performing some
highly specific cleaning that will likely not be relevant in the future.

Next, we specify the Gooogle Sheets spreadsheet we want to connect with
(this will come in handy a bit later).

The next task is creating a reference lookup table for all the
questions, their descriptions, and response descriptions. We will call
this our “Response Key.” First we create a somewhat messy version from
the raw data (**response\_key\_messy**). Then we send it over to Sheets
for some manual cleaning before bringing it back into R, now calling it
**response\_key**. This will be crucial for maintaining consistent
references throughout analysis and visualization.

    ## Reference Lookup Table:

    ##   Question main sub1 sub2
    ## 1     Q1_1   Q1    1 <NA>
    ## 2     Q1_2   Q1    2 <NA>
    ## 3       Q2   Q2 <NA> <NA>
    ##                                                                                            Description
    ## 1 On behalf of the LACN Benchmarking Committee, thank you for taking the time to complete this requ...
    ## 2 On behalf of the LACN Benchmarking Committee, thank you for taking the time to complete this requ...
    ## 3                                                                               To whom do you report?
    ##     Description_short                                  dim1 dim2
    ## 1                <NA> Name of person completing this survey <NA>
    ## 2                <NA>                           Institution <NA>
    ## 3 Reporting Structure                       Selected Choice <NA>

Our final task in this initial section is creating a table of question
types. Some LACN questions are single-response, some are multi-choice
(more than one can be selected), some allow for a matrix of responses
per college, some a continuous numeric input, and one a ordinal ranking.
If we want to automate the cleaning and analysis of the survey
questions, we need to be able to separate out the single-response
questions from the matrix questions, etc. The **question\_type**
dataframe, built manually in Google Sheets and then imported into R. See the Lacn Google Sheets folder for this. The main sheets are the **response_key** tabs and the **progress** tabs. The **progress** tab contains the questions list, while the **response_key** tab is written into Google Sheets by R. Once this is in Google Sheets, edit column names to match previous years' tabs. 

Now we can move to analyzing each question on its own terms.

# Cleaning

Script: **2\_clean.R**

One of the challenges with this data is how *wide* it is. The raw survey
dataframe contains 257 variables. If we want to speed up our analysis,
we need to break the dataset up by question. That way, when we want to
analyze Q8, we can simply handle the Q8 dataset without having to sift
through the entire 257-column raw dataset.

**clean.R** loops through each question and extracts its columns from
the master dataset, along with institution name and enrollment. We then
deposit each of those question-specific dataframes (specified as
**current\_question** in the for loop) into a “list,” which is an object
capable of containing other objects (like dataframes) within it. Now, we
have a nice portable object we can manipulate, explore, and use in later
analysis. Without this list, we would have to repeat ourselves every
time we wanted to extract a single question and analyze it.

Below is a representation of the structure of that list (called
**question\_list**). As you can see, **question\_list**, represented by
the top-most black rectangle, contains within it

    ## █ [1:0x55b31a295da0] <named list> 
    ## ├─Q1 = █ [2:0x55b31a28eda8] <tbl_df[,4]> 
    ## │      ├─Institution Name = [3:0x55b31a295ea0] <chr> 
    ## │      ├─Undergraduate enrollment = [4:0x55b31a296010] <chr> 
    ## │      ├─Q1_1 = [5:0x55b31a296180] <chr> 
    ## │      └─Q1_2 = [6:0x55b31a2962f0] <chr> 
    ## ├─Q2 = █ [7:0x55b31a28ecb8] <tbl_df[,4]> 
    ## │      ├─Institution Name = [8:0x55b31a296460] <chr> 
    ## │      ├─Undergraduate enrollment = [9:0x55b31a2965d0] <chr> 
    ## │      ├─Q2 = [10:0x55b31a296740] <chr> 
    ## │      └─Q2_6_TEXT = [11:0x55b31a2968b0] <chr> 
    ## ├─Q3 = █ [12:0x55b31a28ebc8] <tbl_df[,3]> 
    ## │      ├─Institution Name = [13:0x55b31a296a20] <chr> 
    ## │      ├─Undergraduate enrollment = [14:0x55b31a296b90] <chr> 
    ## │      └─Q3 = [15:0x55b31a296d00] <chr> 
    ## ├─Q4 = █ [16:0x55b31a287c38] <tbl_df[,11]> 
    ## │      ├─Institution Name = [17:0x55b31a296e70] <chr> 
    ## │      ├─Undergraduate enrollment = [18:0x55b31a296fe0] <chr> 
    ## │      ├─Q4_3 = [19:0x55b31a297150] <chr> 
    ## │      ├─Q4_4 = [20:0x55b31a2972c0] <chr> 
    ## │      ├─Q4_5 = [21:0x55b31a297430] <chr> 
    ## │      ├─Q4_6 = [22:0x55b31a2975a0] <chr> 
    ## │      ├─Q4_7 = [23:0x55b31a297710] <chr> 
    ## │      ├─Q4_8 = [24:0x55b31a297880] <chr> 
    ## │      ├─Q4_9 = [25:0x55b31a2979f0] <chr> 
    ## │      ├─Q4_10 = [26:0x55b31a297b60] <chr> 
    ## │      └─Q4_9_TEXT = [27:0x55b31a297cd0] <chr> 
    ## ├─Q5 = █ [28:0x55b31a287ad8] <tbl_df[,14]> 
    ## │      ├─Institution Name = [29:0x55b31a297e40] <chr> 
    ## │      ├─Undergraduate enrollment = [30:0x55b31a297fb0] <chr> 
    ## │      ├─Q5_6 = [31:0x55b31a298120] <chr> 
    ## │      ├─Q5_7 = [32:0x55b31a298290] <chr> 
    ## │      ├─Q5_8 = [33:0x55b31a298400] <chr> 
    ## │      ├─Q5_9 = [34:0x55b31a298570] <chr> 
    ## │      ├─Q5_10 = [35:0x55b31a2986e0] <chr> 
    ## │      ├─Q5_15 = [36:0x55b31a298850] <chr> 
    ## │      ├─Q5_1 = [37:0x55b31a2989c0] <chr> 
    ## │      ├─Q5_16 = [38:0x55b31a298b30] <chr> 
    ## │      ├─Q5_11 = [39:0x55b31a298ca0] <chr> 
    ## │      ├─Q5_12 = [40:0x55b31a298e10] <chr> 
    ## │      ├─Q5_13 = [41:0x55b31a298f80] <chr> 
    ## │      └─Q5_13_TEXT = [42:0x55b31a2990f0] <chr> 
    ## ├─Q6 = █ [43:0x55b31a292f98] <tbl_df[,8]> 
    ## │      ├─Institution Name = [44:0x55b31a299260] <chr> 
    ## │      ├─Undergraduate enrollment = [45:0x55b31a2993d0] <chr> 
    ## │      ├─Q6_1_1 = [46:0x55b31a299540] <chr> 
    ## │      ├─Q6_1_2 = [47:0x55b31a2996b0] <chr> 
    ## │      ├─Q6_2_1 = [48:0x55b31a299820] <chr> 
    ## │      ├─Q6_2_2 = [49:0x55b31a299990] <chr> 
    ## │      ├─Q6_3_1 = [50:0x55b31a299b00] <chr> 
    ## │      └─Q6_3_2 = [51:0x55b31a299c70] <chr> 
    ## ├─Q7 = █ [52:0x55b31a292eb8] <tbl_df[,8]> 
    ## │      ├─Institution Name = [53:0x55b31a299de0] <chr> 
    ## │      ├─Undergraduate enrollment = [54:0x55b31a299f50] <chr> 
    ## │      ├─Q7_1_9 = [55:0x55b31a29a0c0] <chr> 
    ## │      ├─Q7_1_2 = [56:0x55b31a29a230] <chr> 
    ## │      ├─Q7_1_3 = [57:0x55b31a29a3a0] <chr> 
    ## │      ├─Q7_1_4 = [58:0x55b31a29a510] <chr> 
    ## │      ├─Q7_1_5 = [59:0x55b31a29a680] <chr> 
    ## │      └─Q7_1_10 = [60:0x55b31a29a7f0] <chr> 
    ## ├─Q8 = █ [61:0x55b31a29a960] <tbl_df[,44]> 
    ## │      ├─Institution Name = [62:0x55b31a29ab00] <chr> 
    ## │      ├─Undergraduate enrollment = [63:0x55b31a29ac70] <chr> 
    ## │      ├─Q8_1_1 = [64:0x55b31a29ade0] <chr> 
    ## │      ├─Q8_1_2 = [65:0x55b31a29af50] <chr> 
    ## │      ├─Q8_1_3 = [66:0x55b31a29b0c0] <chr> 
    ## │      ├─Q8_2_1 = [67:0x55b31a29b230] <chr> 
    ## │      ├─Q8_2_2 = [68:0x55b31a29b3a0] <chr> 
    ## │      ├─Q8_2_3 = [69:0x55b31a29b510] <chr> 
    ## │      ├─Q8_3_1 = [70:0x55b31a29b680] <chr> 
    ## │      ├─Q8_3_2 = [71:0x55b31a29b7f0] <chr> 
    ## │      ├─Q8_3_3 = [72:0x55b31a29b960] <chr> 
    ## │      ├─Q8_4_1 = [73:0x55b31a29bad0] <chr> 
    ## │      ├─Q8_4_2 = [74:0x55b31a29bc40] <chr> 
    ## │      ├─Q8_4_3 = [75:0x55b31a29bdb0] <chr> 
    ## │      ├─Q8_5_1 = [76:0x55b31a29bf20] <chr> 
    ## │      ├─Q8_5_2 = [77:0x55b31a29c090] <chr> 
    ## │      ├─Q8_5_3 = [78:0x55b31a29c200] <chr> 
    ## │      ├─Q8_6_1 = [79:0x55b31a29c370] <chr> 
    ## │      ├─Q8_6_2 = [80:0x55b31a29c4e0] <chr> 
    ## │      ├─Q8_6_3 = [81:0x55b31a29c650] <chr> 
    ## │      ├─Q8_7_1 = [82:0x55b31a29c7c0] <chr> 
    ## │      ├─Q8_7_2 = [83:0x55b31a29c930] <chr> 
    ## │      ├─Q8_7_3 = [84:0x55b31a29caa0] <chr> 
    ## │      ├─Q8_8_1 = [85:0x55b31a29cc10] <chr> 
    ## │      ├─Q8_8_2 = [86:0x55b31a29cd80] <chr> 
    ## │      ├─Q8_8_3 = [87:0x55b31a29cef0] <chr> 
    ## │      ├─Q8_9_1 = [88:0x55b31a29d060] <chr> 
    ## │      ├─Q8_9_2 = [89:0x55b31a29d1d0] <chr> 
    ## │      ├─Q8_9_3 = [90:0x55b31a29d340] <chr> 
    ## │      ├─Q8_10_1 = [91:0x55b31a29d4b0] <chr> 
    ## │      ├─Q8_10_2 = [92:0x55b31a29d620] <chr> 
    ## │      ├─Q8_10_3 = [93:0x55b31a29d790] <chr> 
    ## │      ├─Q8_11_1 = [94:0x55b31a29d900] <chr> 
    ## │      ├─Q8_11_2 = [95:0x55b31a29da70] <chr> 
    ## │      ├─Q8_11_3 = [96:0x55b31a29dbe0] <chr> 
    ## │      ├─Q8_12_1 = [97:0x55b31a29dd50] <chr> 
    ## │      ├─Q8_12_2 = [98:0x55b31a29dec0] <chr> 
    ## │      ├─Q8_12_3 = [99:0x55b31a29e030] <chr> 
    ## │      ├─Q8_13_1 = [100:0x55b31a29e1a0] <chr> 
    ## │      ├─Q8_13_2 = [101:0x55b31a29e310] <chr> 
    ## │      ├─Q8_13_3 = [102:0x55b31a29e480] <chr> 
    ## │      ├─Q8_14_1 = [103:0x55b31a29e5f0] <chr> 
    ## │      ├─Q8_14_2 = [104:0x55b31a29e760] <chr> 
    ## │      └─Q8_14_3 = [105:0x55b31a29e8d0] <chr> 
    ## ├─Q9 = █ [106:0x55b31a287978] <tbl_df[,14]> 
    ## │      ├─Institution Name = [107:0x55b31a29ebe0] <chr> 
    ## │      ├─Undergraduate enrollment = [108:0x55b31a29ed50] <chr> 
    ## │      ├─Q9_1 = [109:0x55b31a29eec0] <chr> 
    ## │      ├─Q9_2 = [110:0x55b31a29f030] <chr> 
    ## │      ├─Q9_3 = [111:0x55b31a29f1a0] <chr> 
    ## │      ├─Q9_4 = [112:0x55b31a29f310] <chr> 
    ## │      ├─Q9_5 = [113:0x55b31a29f480] <chr> 
    ## │      ├─Q9_6 = [114:0x55b31a29f5f0] <chr> 
    ## │      ├─Q9_7 = [115:0x55b31a29f760] <chr> 
    ## │      ├─Q9_8 = [116:0x55b31a29f8d0] <chr> 
    ## │      ├─Q9_9 = [117:0x55b31a29fa40] <chr> 
    ## │      ├─Q9_10 = [118:0x55b31a29fbb0] <chr> 
    ## │      ├─Q9_11 = [119:0x55b31a29fd20] <chr> 
    ## │      └─Q9_11_TEXT = [120:0x55b31a29fe90] <chr> 
    ## ├─Q10 = █ [121:0x55b31a287818] <tbl_df[,14]> 
    ## │       ├─Institution Name = [122:0x55b31a2a0000] <chr> 
    ## │       ├─Undergraduate enrollment = [123:0x55b31a2a0170] <chr> 
    ## │       ├─Q10_1 = [124:0x55b31a2a02e0] <chr> 
    ## │       ├─Q10_3 = [125:0x55b31a2a0450] <chr> 
    ## │       ├─Q10_4 = [126:0x55b31a2a05c0] <chr> 
    ## │       ├─Q10_5 = [127:0x55b31a2a0730] <chr> 
    ## │       ├─Q10_6 = [128:0x55b31a2a08a0] <chr> 
    ## │       ├─Q10_7 = [129:0x55b31a2a0a10] <chr> 
    ## │       ├─Q10_8 = [130:0x55b31a2a0b80] <chr> 
    ## │       ├─Q10_10 = [131:0x55b31a2a0cf0] <chr> 
    ## │       ├─Q10_11 = [132:0x55b31a2a0e60] <chr> 
    ## │       ├─Q10_12 = [133:0x55b31a2a0fd0] <chr> 
    ## │       ├─Q10_13 = [134:0x55b31a2a1140] <chr> 
    ## │       └─Q10_13_TEXT = [135:0x55b31a2a12b0] <chr> 
    ## ├─Q11 = █ [136:0x55b31a2a1420] <tbl_df[,26]> 
    ## │       ├─Institution Name = [137:0x55b31a2a1530] <chr> 
    ## │       ├─Undergraduate enrollment = [138:0x55b31a2a16a0] <chr> 
    ## │       ├─Q11_27 = [139:0x55b31a2a1810] <chr> 
    ## │       ├─Q11_1 = [140:0x55b31a2a1980] <chr> 
    ## │       ├─Q11_2 = [141:0x55b31a2a1af0] <chr> 
    ## │       ├─Q11_4 = [142:0x55b31a2a1c60] <chr> 
    ## │       ├─Q11_5 = [143:0x55b31a2a1dd0] <chr> 
    ## │       ├─Q11_6 = [144:0x55b31a2a1f40] <chr> 
    ## │       ├─Q11_16 = [145:0x55b31a2a20b0] <chr> 
    ## │       ├─Q11_11 = [146:0x55b31a2a2220] <chr> 
    ## │       ├─Q11_12 = [147:0x55b31a2a2390] <chr> 
    ## │       ├─Q11_7 = [148:0x55b31a2a2500] <chr> 
    ## │       ├─Q11_3 = [149:0x55b31a2a2670] <chr> 
    ## │       ├─Q11_32 = [150:0x55b31a2a27e0] <chr> 
    ## │       ├─Q11_33 = [151:0x55b31a2a2950] <chr> 
    ## │       ├─Q11_34 = [152:0x55b31a2a2ac0] <chr> 
    ## │       ├─Q11_31 = [153:0x55b31a2a2c30] <chr> 
    ## │       ├─Q11_13 = [154:0x55b31a2a2da0] <chr> 
    ## │       ├─Q11_14 = [155:0x55b31a2a2f10] <chr> 
    ## │       ├─Q11_8 = [156:0x55b31a2a3080] <chr> 
    ## │       ├─Q11_28 = [157:0x55b31a2a31f0] <chr> 
    ## │       ├─Q11_9 = [158:0x55b31a2a3360] <chr> 
    ## │       ├─Q11_10 = [159:0x55b31a2a34d0] <chr> 
    ## │       ├─Q11_15 = [160:0x55b31a2a3640] <chr> 
    ## │       ├─Q11_29 = [161:0x55b31a2a37b0] <chr> 
    ## │       └─Q11_29_TEXT = [162:0x55b31a2a3920] <chr> 
    ## ├─Q12 = █ [163:0x55b31a28e858] <tbl_df[,3]> 
    ## │       ├─Institution Name = [164:0x55b31a2a3ba0] <chr> 
    ## │       ├─Undergraduate enrollment = [165:0x55b31a2a3d10] <chr> 
    ## │       └─Q12 = [166:0x55b31a2a3e80] <chr> 
    ## ├─Q13 = █ [167:0x55b31a292dd8] <tbl_df[,7]> 
    ## │       ├─Institution Name = [168:0x55b31a2a3ff0] <chr> 
    ## │       ├─Undergraduate enrollment = [169:0x55b31a2a4160] <chr> 
    ## │       ├─Q13_1 = [170:0x55b31a2a42d0] <chr> 
    ## │       ├─Q13_2 = [171:0x55b31a2a4440] <chr> 
    ## │       ├─Q13_3 = [172:0x55b31a2a45b0] <chr> 
    ## │       ├─Q13_4 = [173:0x55b31a2a4720] <chr> 
    ## │       └─Q13_4_TEXT = [174:0x55b31a2a4890] <chr> 
    ## ├─Q14 = █ [175:0x55b31a2a68a8] <tbl_df[,3]> 
    ## │       ├─Institution Name = [176:0x55b31a2a6920] <chr> 
    ## │       ├─Undergraduate enrollment = [177:0x55b31a2a6a90] <chr> 
    ## │       └─Q14 = [178:0x55b31a2a6c00] <chr> 
    ## ├─Q15 = █ [179:0x55b31a2a67b8] <tbl_df[,3]> 
    ## │       ├─Institution Name = [180:0x55b31a2a6d70] <chr> 
    ## │       ├─Undergraduate enrollment = [181:0x55b31a2a6ee0] <chr> 
    ## │       └─Q15 = [182:0x55b31a2a7050] <chr> 
    ## ├─Q16 = █ [183:0x55b31a2a66c8] <tbl_df[,4]> 
    ## │       ├─Institution Name = [184:0x55b31a2a71c0] <chr> 
    ## │       ├─Undergraduate enrollment = [185:0x55b31a2a7330] <chr> 
    ## │       ├─Q16 = [186:0x55b31a2a74a0] <chr> 
    ## │       └─Q16_2_TEXT = [187:0x55b31a2a7610] <chr> 
    ## ├─Q36 = █ [188:0x55b31a2876b8] <tbl_df[,14]> 
    ## │       ├─Institution Name = [189:0x55b31a2a7780] <chr> 
    ## │       ├─Undergraduate enrollment = [190:0x55b31a2a78f0] <chr> 
    ## │       ├─Q36_1_1 = [191:0x55b31a2a7a60] <chr> 
    ## │       ├─Q36_1_2 = [192:0x55b31a2a7bd0] <chr> 
    ## │       ├─Q36_2_1 = [193:0x55b31a2a7d40] <chr> 
    ## │       ├─Q36_2_2 = [194:0x55b31a2a7eb0] <chr> 
    ## │       ├─Q36_3_1 = [195:0x55b31a2a8020] <chr> 
    ## │       ├─Q36_3_2 = [196:0x55b31a2a8190] <chr> 
    ## │       ├─Q36_4_1 = [197:0x55b31a2a8300] <chr> 
    ## │       ├─Q36_4_2 = [198:0x55b31a2a8470] <chr> 
    ## │       ├─Q36_5_1 = [199:0x55b31a2a85e0] <chr> 
    ## │       ├─Q36_5_2 = [200:0x55b31a2a8750] <chr> 
    ## │       ├─Q36_6_1 = [201:0x55b31a2a88c0] <chr> 
    ## │       └─Q36_6_2 = [202:0x55b31a2a8a30] <chr> 
    ## ├─Q37 = █ [203:0x55b31a287558] <tbl_df[,10]> 
    ## │       ├─Institution Name = [204:0x55b31a2a8ba0] <chr> 
    ## │       ├─Undergraduate enrollment = [205:0x55b31a2a8d10] <chr> 
    ## │       ├─Q37_1_1 = [206:0x55b31a2a8e80] <chr> 
    ## │       ├─Q37_1_2 = [207:0x55b31a2a8ff0] <chr> 
    ## │       ├─Q37_2_1 = [208:0x55b31a2a9160] <chr> 
    ## │       ├─Q37_2_2 = [209:0x55b31a2a92d0] <chr> 
    ## │       ├─Q37_3_1 = [210:0x55b31a2a9440] <chr> 
    ## │       ├─Q37_3_2 = [211:0x55b31a2a95b0] <chr> 
    ## │       ├─Q37_4_1 = [212:0x55b31a2a9720] <chr> 
    ## │       └─Q37_4_2 = [213:0x55b31a2a9890] <chr> 
    ## ├─Q19 = █ [214:0x55b31a292cf8] <tbl_df[,6]> 
    ## │       ├─Institution Name = [215:0x55b31a2ab920] <chr> 
    ## │       ├─Undergraduate enrollment = [216:0x55b31a2aba90] <chr> 
    ## │       ├─Q19_1 = [217:0x55b31a2abc00] <chr> 
    ## │       ├─Q19_2 = [218:0x55b31a2abd70] <chr> 
    ## │       ├─Q19_3 = [219:0x55b31a2abee0] <chr> 
    ## │       └─Q19_4 = [220:0x55b31a2ac050] <chr> 
    ## ├─Q20 = █ [221:0x55b31a2ab798] <tbl_df[,14]> 
    ## │       ├─Institution Name = [222:0x55b31a2ac1c0] <chr> 
    ## │       ├─Undergraduate enrollment = [223:0x55b31a2ac330] <chr> 
    ## │       ├─Q20_1_1 = [224:0x55b31a2ac4a0] <chr> 
    ## │       ├─Q20_1_2 = [225:0x55b31a2ac610] <chr> 
    ## │       ├─Q20_2_1 = [226:0x55b31a2ac780] <chr> 
    ## │       ├─Q20_2_2 = [227:0x55b31a2ac8f0] <chr> 
    ## │       ├─Q20_3_1 = [228:0x55b31a2aca60] <chr> 
    ## │       ├─Q20_3_2 = [229:0x55b31a2acbd0] <chr> 
    ## │       ├─Q20_4_1 = [230:0x55b31a2acd40] <chr> 
    ## │       ├─Q20_4_2 = [231:0x55b31a2aceb0] <chr> 
    ## │       ├─Q20_5_1 = [232:0x55b31a2ad020] <chr> 
    ## │       ├─Q20_5_2 = [233:0x55b31a2ad190] <chr> 
    ## │       ├─Q20_6_1 = [234:0x55b31a2ad300] <chr> 
    ## │       └─Q20_6_2 = [235:0x55b31a2ad470] <chr> 
    ## ├─Q21 = █ [236:0x55b31a2ad5e0] <tbl_df[,22]> 
    ## │       ├─Institution Name = [237:0x55b31a2ad6d0] <chr> 
    ## │       ├─Undergraduate enrollment = [238:0x55b31a2ad840] <chr> 
    ## │       ├─Q21_1_5 = [239:0x55b31a2ad9b0] <chr> 
    ## │       ├─Q21_1_2 = [240:0x55b31a2adb20] <chr> 
    ## │       ├─Q21_1_3 = [241:0x55b31a2adc90] <chr> 
    ## │       ├─Q21_1_4 = [242:0x55b31a2ade00] <chr> 
    ## │       ├─Q21_2_5 = [243:0x55b31a2adf70] <chr> 
    ## │       ├─Q21_2_2 = [244:0x55b31a2ae0e0] <chr> 
    ## │       ├─Q21_2_3 = [245:0x55b31a2ae250] <chr> 
    ## │       ├─Q21_2_4 = [246:0x55b31a2ae3c0] <chr> 
    ## │       ├─Q21_3_5 = [247:0x55b31a2ae530] <chr> 
    ## │       ├─Q21_3_2 = [248:0x55b31a2ae6a0] <chr> 
    ## │       ├─Q21_3_3 = [249:0x55b31a2ae810] <chr> 
    ## │       ├─Q21_3_4 = [250:0x55b31a2ae980] <chr> 
    ## │       ├─Q21_4_5 = [251:0x55b31a2aeaf0] <chr> 
    ## │       ├─Q21_4_2 = [252:0x55b31a2aec60] <chr> 
    ## │       ├─Q21_4_3 = [253:0x55b31a2aedd0] <chr> 
    ## │       ├─Q21_4_4 = [254:0x55b31a2aef40] <chr> 
    ## │       ├─Q21_5_5 = [255:0x55b31a2af0b0] <chr> 
    ## │       ├─Q21_5_2 = [256:0x55b31a2af220] <chr> 
    ## │       ├─Q21_5_3 = [257:0x55b31a2af390] <chr> 
    ## │       └─Q21_5_4 = [258:0x55b31a2af500] <chr> 
    ## ├─Q22 = █ [259:0x55b31a292c18] <tbl_df[,8]> 
    ## │       ├─Institution Name = [260:0x55b31a2af760] <chr> 
    ## │       ├─Undergraduate enrollment = [261:0x55b31a2af8d0] <chr> 
    ## │       ├─Q22_1_1 = [262:0x55b31a2afa40] <chr> 
    ## │       ├─Q22_2_1 = [263:0x55b31a2afbb0] <chr> 
    ## │       ├─Q22_3_1 = [264:0x55b31a2afd20] <chr> 
    ## │       ├─Q22_4_1 = [265:0x55b31a2afe90] <chr> 
    ## │       ├─Q22_5_1 = [266:0x55b31a2b0000] <chr> 
    ## │       └─Q22_6_1 = [267:0x55b31a2b0170] <chr> 
    ## ├─Q23 = █ [268:0x55b31a292b38] <tbl_df[,5]> 
    ## │       ├─Institution Name = [269:0x55b31a2b02e0] <chr> 
    ## │       ├─Undergraduate enrollment = [270:0x55b31a2b0450] <chr> 
    ## │       ├─Q23_1 = [271:0x55b31a2b05c0] <chr> 
    ## │       ├─Q23_4 = [272:0x55b31a2b0730] <chr> 
    ## │       └─Q23_2 = [273:0x55b31a2b08a0] <chr> 
    ## ├─Q24 = █ [274:0x55b31a2ab638] <tbl_df[,11]> 
    ## │       ├─Institution Name = [275:0x55b31a2b0a10] <chr> 
    ## │       ├─Undergraduate enrollment = [276:0x55b31a2b0b80] <chr> 
    ## │       ├─Q24_1_1 = [277:0x55b31a2b0cf0] <chr> 
    ## │       ├─Q24_1_2 = [278:0x55b31a2b0e60] <chr> 
    ## │       ├─Q24_1_5 = [279:0x55b31a2b0fd0] <chr> 
    ## │       ├─Q24_2_1 = [280:0x55b31a2b1140] <chr> 
    ## │       ├─Q24_2_2 = [281:0x55b31a2b12b0] <chr> 
    ## │       ├─Q24_2_5 = [282:0x55b31a2b1420] <chr> 
    ## │       ├─Q24_3_1 = [283:0x55b31a2b1590] <chr> 
    ## │       ├─Q24_3_2 = [284:0x55b31a2b1700] <chr> 
    ## │       └─Q24_3_5 = [285:0x55b31a2b1870] <chr> 
    ## └─Q25 = █ [286:0x55b31a2a6358] <tbl_df[,3]> 
    ##         ├─Institution Name = [287:0x55b31a2b19e0] <chr> 
    ##         ├─Undergraduate enrollment = [288:0x55b31a2b1b50] <chr> 
    ##         └─Q25 = [289:0x55b31a2b1cc0] <chr>

# Functions for Analysis

Script: **3\_functions.R**

## Motivation

To get a sense for why the following custom functions are useful, let’s
inspect some of the raw data.

Below are several questions from the survey.

    ## Question 2

    ## # A data frame: 6 × 4
    ##   `Institution Name`            `Undergraduate enrollment` Q2          Q2_6_TEXT
    ## * <chr>                         <chr>                      <chr>       <chr>    
    ## 1 Vassar College                2439                       Student Af… <NA>     
    ## 2 Williams College              2094                       Other:      Office o…
    ## 3 Brandeis University           3688                       Student Af… <NA>     
    ## 4 College of the Holy Cross     2963                       Academic A… <NA>     
    ## 5 Franklin and Marshall College 2315                       Student Af… <NA>     
    ## 6 Skidmore College              2662                       Student Af… <NA>

    ## 
    ## Question 4

    ## # A data frame: 6 × 11
    ##   `Institution Name`  `Undergraduate…` Q4_3  Q4_4  Q4_5  Q4_6  Q4_7  Q4_8  Q4_9 
    ## * <chr>               <chr>            <chr> <chr> <chr> <chr> <chr> <chr> <chr>
    ## 1 Vassar College      2439             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## 2 Williams College    2094             <NA>  Alum… <NA>  <NA>  <NA>  <NA>  <NA> 
    ## 3 Brandeis University 3688             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## 4 College of the Hol… 2963             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## 5 Franklin and Marsh… 2315             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## 6 Skidmore College    2662             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## # … with 2 more variables: Q4_10 <chr>, Q4_9_TEXT <chr>

    ## 
    ## Question 5

    ## # A data frame: 6 × 14
    ##   `Institution Name`  `Undergraduate…` Q5_6  Q5_7  Q5_8  Q5_9  Q5_10 Q5_15 Q5_1 
    ## * <chr>               <chr>            <chr> <chr> <chr> <chr> <chr> <chr> <chr>
    ## 1 Vassar College      2439             2     9     6     8     3     4     1    
    ## 2 Williams College    2094             1     7     6     9     4     3     5    
    ## 3 Brandeis University 3688             1     6     5     7     3     4     8    
    ## 4 College of the Hol… 2963             2     3     9     7     1     4     8    
    ## 5 Franklin and Marsh… 2315             2     4     3     8     5     6     1    
    ## 6 Skidmore College    2662             <NA>  <NA>  <NA>  <NA>  <NA>  <NA>  <NA> 
    ## # … with 5 more variables: Q5_16 <chr>, Q5_11 <chr>, Q5_12 <chr>, Q5_13 <chr>,
    ## #   Q5_13_TEXT <chr>

    ## 
    ## Question 6

    ## # A data frame: 6 × 8
    ##   `Institution Name`  `Undergraduate…` Q6_1_1 Q6_1_2 Q6_2_1 Q6_2_2 Q6_3_1 Q6_3_2
    ## * <chr>               <chr>            <chr>  <chr>  <chr>  <chr>  <chr>  <chr> 
    ## 1 Vassar College      2439             5      0      4      0      0      0     
    ## 2 Williams College    2094             8      0      16     0      0      0     
    ## 3 Brandeis University 3688             6      0      3      1      0      0     
    ## 4 College of the Hol… 2963             8      0      0      0      0      0     
    ## 5 Franklin and Marsh… 2315             0      0      10     0      0      0     
    ## 6 Skidmore College    2662             9      0      4      0      0      0

    ## 
    ## Question 7

    ## # A data frame: 6 × 8
    ##   `Institution Name` `Undergraduate…` Q7_1_9 Q7_1_2 Q7_1_3 Q7_1_4 Q7_1_5 Q7_1_10
    ## * <chr>              <chr>            <chr>  <chr>  <chr>  <chr>  <chr>  <chr>  
    ## 1 Vassar College     2439             9      8      0      0      1      8.25   
    ## 2 Williams College   2094             11     10     0      0      1      10     
    ## 3 Brandeis Universi… 3688             15     14     1      0      0      14.85  
    ## 4 College of the Ho… 2963             11     8      0.83   0.5    0.42   9.75   
    ## 5 Franklin and Mars… 2315             10     7      3      0      0      10     
    ## 6 Skidmore College   2662             10     7      1      0      2      8.75

A brief inspection of these questions (and the original survey format)
reveals their widely varying structure. Question 2 allows for only one
response per participant, while Question 4 allows for multiple
responses. Question 5 requires each respondent to rank a list of items,
Question 6 provides a matrix for the respondent to fill in, and Question
7 asks for an unbounded numeric input reflecting the number of FTE
professional staff.

Here, we’re faced with a choice. First, we could analyze each of the 23
questions individually. While that is the most attractive option up
front, pursuing that path quickly presents a problem: we will end up
duplicating work when one question has the same form as an earlier one
and therefore can be analyzed using essentially the same method.
Questions 2 and 3, for example, are both single-response items. If we
analyzed them separately, we would probably just copy and paste the code
from Question 2 in order to work with Question 3.

Our second option, then, is to build some functions that can deal with
each of these question types efficiently. There are only five types:
single, multi, matrix, continuous, and ranking. That is a much more
manageable problem.

The challenge with this approach is building the functions. Custom
functions can be a bit intimidating at first, but what they lack in
simplicity they make up for in speed.

## Functions

Script: **3\_functions.R**

Note: the summarising method of the functions can be adjusted. Currently
they return averages when relevant, but we can change this to, for
example, sum with little difficulty.

### Helper Functions

In **lacn\_functions.R**, we find a handful of functions. First up are
two helper functions: *selectionFunction*, which returns a vector of
questions (e.g., c(“Q4”,“Q7”,“Q2”…)) that belong to a certain question
type, like “matrix”, and *keyFunction*, which returns a reference table
for response labels. Don’t worry too much about these; they just end up
getting wrapped into the main functions below.

### Analysis Functions

The four main types of question each get their own function (single,
multi, matrix, and continuous). *Ranking* does not, as there is only one
such question; building a function would be more trouble than it’s
worth. Without getting into too much detail, here’s how each of them
works

#### Single Function and Multi Function

Both of these merely group and aggregate the number of times each
response was selected, then add a variable for the relative frequency of
each response (with the denominator being the total number of
respondents).

    ## Original data:

    ## # A data frame: 6 × 4
    ##   `Institution Name`            `Undergraduate enrollment` Q2          Q2_6_TEXT
    ## * <chr>                         <chr>                      <chr>       <chr>    
    ## 1 Vassar College                2439                       Student Af… <NA>     
    ## 2 Williams College              2094                       Other:      Office o…
    ## 3 Brandeis University           3688                       Student Af… <NA>     
    ## 4 College of the Holy Cross     2963                       Academic A… <NA>     
    ## 5 Franklin and Marshall College 2315                       Student Af… <NA>     
    ## 6 Skidmore College              2662                       Student Af… <NA>

    ## 
    ## Aggregated data:

    ## # A data frame: 6 × 3
    ##   Q2                         n   freq
    ## * <chr>                  <int>  <dbl>
    ## 1 Academic Affairs          12 0.308 
    ## 2 Alumni and Development     6 0.154 
    ## 3 Enrollment Management      1 0.0256
    ## 4 Other:                     3 0.0769
    ## 5 President                  2 0.0513
    ## 6 Student Affairs           15 0.385

#### Matrix Function

The matrix function pivots then unpivots each question so that the
matrix format of the original survey is recovered. It then summarises
the responses in each cell.

    ## Original data:

    ## # A data frame: 6 × 8
    ##   `Institution Name`  `Undergraduate…` Q6_1_1 Q6_1_2 Q6_2_1 Q6_2_2 Q6_3_1 Q6_3_2
    ## * <chr>               <chr>            <chr>  <chr>  <chr>  <chr>  <chr>  <chr> 
    ## 1 Vassar College      2439             5      0      4      0      0      0     
    ## 2 Williams College    2094             8      0      16     0      0      0     
    ## 3 Brandeis University 3688             6      0      3      1      0      0     
    ## 4 College of the Hol… 2963             8      0      0      0      0      0     
    ## 5 Franklin and Marsh… 2315             0      0      10     0      0      0     
    ## 6 Skidmore College    2662             9      0      4      0      0      0

    ## 
    ## Aggregated data:

    ##            dim2 Students in paraprofessional roles
    ## 1 Undergraduate                          8.4736842
    ## 2      Graduate                          0.2051282
    ##   Students in administrative roles
    ## 1                       4.73684211
    ## 2                       0.02564103
    ##   Students in "hybrid" roles (e.g., student workers have both paraprofessional and administrative duties)
    ## 1                                                                                                1.871795
    ## 2                                                                                                0.000000

#### Continuous Function

The continuous function pivots and aggregates data by response to return
some statistic on each response category.

    ## Original data:

    ## # A data frame: 6 × 8
    ##   `Institution Name` `Undergraduate…` Q7_1_9 Q7_1_2 Q7_1_3 Q7_1_4 Q7_1_5 Q7_1_10
    ## * <chr>              <chr>            <chr>  <chr>  <chr>  <chr>  <chr>  <chr>  
    ## 1 Vassar College     2439             9      8      0      0      1      8.25   
    ## 2 Williams College   2094             11     10     0      0      1      10     
    ## 3 Brandeis Universi… 3688             15     14     1      0      0      14.85  
    ## 4 College of the Ho… 2963             11     8      0.83   0.5    0.42   9.75   
    ## 5 Franklin and Mars… 2315             10     7      3      0      0      10     
    ## 6 Skidmore College   2662             10     7      1      0      2      8.75

    ## 
    ## Aggregated data:

    ## # A data frame: 6 × 2
    ##   dim2                                                 mean
    ## * <chr>                                               <dbl>
    ## 1 # FT staff, academic year (or less than 12 months)  0.917
    ## 2 # FT staff, full year (12 months)                   8.85 
    ## 3 # PT Staff, academic year (or less than 12 months)  0.524
    ## 4 # PT staff, full year (12 months)                   0.75 
    ## 5 Total # of staff (headcount)                       10.4  
    ## 6 Total FTE                                           9.77

#### Ranking Analysis

The ranking question (Q5) doesn’t get its own function. Here’s how the
analysis works (see **analysis.R**). We simply compute the desired
statistic for the ranking of each “priority” (student engagment, first
destination data) and then pivot the resultant dataset in anticipation
of visualization.

#### Analyze Function

Finally, the analyze function allows us to do all of the above analysis
for each question type in just a few lines of code (see next section).

#### Visualization Functions

-   matrixPlot plots matrix questions on a barchart
-   singlePlot plots single-answer questions on an averaged barchart
-   tableViz produces the N/Mean/Median/Max/Min/\[college\] summary
    tables
-   nTab produces rendered text output for stand-alone statements like
    “N = 35” \* serviceTab creates service/program tally tables
-   serviceCustom adds a customized school-level column to a
    service/program dataframe in preparation for producing a custom
    serviceTab table. See use cases in **custom\_template.Rmd** by
    searching “serviceCustom”

# Analysis

Script: **4\_analysis.R**

Next, we apply the functions we built to the original data we have
stored in **question\_list**. The analyzeFunction that we built above
allows us analyze any set of questions. That is, if we choose only the
“single” questions, it will apply the singleFunction to them.

The map function (see [purrr](https://purrr.tidyverse.org/) for more)
allows us to do exactly this. Let me explain the code below:

    ## all_questions:

    ## [1] "single"     "multi"      "matrix"     "continuous"

``` r
all_list <- map(all_questions,
                ~ analyzeFunction(
                  .x
                )
)
```

The first argument in the map function is the **all\_questions** vector.
The second argument is the function we want to apply to each element in
that vector (the ‘.x’ is just a placeholder to represent each element in
the vector). So first it will apply the singleFunction to the single
questions, then the multiFunction to the multi questions, and so on,
storing each question type separately in the list we’re calling
**all\_list**. After this code, the **analysis.R** script goes on to add
the ranking question into **all\_list** separately, as it did not have a
function.

## What did we create?

We now have a list containing the cleaned and summarised data for each
type of question (single, multi, matrix, continuous, ranking). See the
structure map below to get a sense of how the final data is stored. It
can look a bit chaotic at first, but the basic idea is this: the master
list contains different question types, which each contain the relevant
questions, which each contain the actual variables and data for each
summarised and aggregated response.

    ## █ [1:0x55b31a2926d8] <named list> 
    ## ├─single = █ [2:0x55b31a292668] <named list> 
    ## │          ├─Q2 = █ [3:0x55b31a2a4fa8] <tbl_df[,3]> 
    ## │          │      ├─Q2 = [4:0x55b31a2925f8] <chr> 
    ## │          │      ├─n = [5:0x55b31a2a4f58] <int> 
    ## │          │      └─freq = [6:0x55b31a292588] <dbl> 
    ## │          ├─Q3 = █ [7:0x55b31a2a4e68] <tbl_df[,3]> 
    ## │          │      ├─Q3 = [8:0x55b31a2a4e18] <chr> 
    ## │          │      ├─n = [9:0x55b31a2b42b8] <int> 
    ## │          │      └─freq = [10:0x55b31a2a4dc8] <dbl> 
    ## │          ├─Q12 = █ [11:0x55b31a2a4cd8] <tbl_df[,3]> 
    ## │          │       ├─Q12 = [12:0x55b31a2a4c88] <chr> 
    ## │          │       ├─n = [13:0x55b31a2b4278] <int> 
    ## │          │       └─freq = [14:0x55b31a2a4c38] <dbl> 
    ## │          ├─Q14 = █ [15:0x55b31a2a4b48] <tbl_df[,3]> 
    ## │          │       ├─Q14 = [16:0x55b31a2937b8] <chr> 
    ## │          │       ├─n = [17:0x55b31a293780] <int> 
    ## │          │       └─freq = [18:0x55b31a293748] <dbl> 
    ## │          ├─Q16 = █ [19:0x55b31a2a4a58] <tbl_df[,3]> 
    ## │          │       ├─Q16 = [20:0x55b31a2ba5c8] <chr> 
    ## │          │       ├─n = [21:0x55b31a2ba590] <int> 
    ## │          │       └─freq = [22:0x55b31a2ba558] <dbl> 
    ## │          └─Q25 = █ [23:0x55b31a2bc498] <tbl_df[,3]> 
    ## │                  ├─Q25 = [24:0x55b31a2ba4e8] <chr> 
    ## │                  ├─n = [25:0x55b31a2ba4b0] <int> 
    ## │                  └─freq = [26:0x55b31a2ba478] <dbl> 
    ## ├─multi = █ [27:0x55b31a2924a8] <named list> 
    ## │         ├─Q4 = █ [28:0x55b31a2bc3a8] <tbl_df[,3]> 
    ## │         │      ├─value = [29:0x55b31a2ab2c8] <chr> 
    ## │         │      ├─n = [30:0x55b31a292438] <int> 
    ## │         │      └─freq = [31:0x55b31a2ab218] <dbl> 
    ## │         ├─Q9 = █ [32:0x55b31a2bc2b8] <tbl_df[,3]> 
    ## │         │      ├─value = [33:0x55b31a2bc560] <chr> 
    ## │         │      ├─n = [34:0x55b31a2ab168] <int> 
    ## │         │      └─freq = [35:0x55b31a2bc670] <dbl> 
    ## │         ├─Q10 = █ [36:0x55b31a2bc1c8] <tbl_df[,3]> 
    ## │         │       ├─value = [37:0x55b31a2bc780] <chr> 
    ## │         │       ├─n = [38:0x55b31a2ab0b8] <int> 
    ## │         │       └─freq = [39:0x55b31a2bc870] <dbl> 
    ## │         ├─Q11 = █ [40:0x55b31a2bc0d8] <tbl_df[,3]> 
    ## │         │       ├─value = [41:0x55b31a2bc960] <chr> 
    ## │         │       ├─n = [42:0x55b31a2ab008] <int> 
    ## │         │       └─freq = [43:0x55b31a2bca80] <dbl> 
    ## │         ├─Q13 = █ [44:0x55b31a2bbfe8] <tbl_df[,3]> 
    ## │         │       ├─value = [45:0x55b31a2923c8] <chr> 
    ## │         │       ├─n = [46:0x55b31a2bbf98] <int> 
    ## │         │       └─freq = [47:0x55b31a292358] <dbl> 
    ## │         └─Q15 = █ [48:0x55b31a2bbea8] <tbl_df[,3]> 
    ## │                 ├─value = [49:0x55b31a2922e8] <chr> 
    ## │                 ├─n = [50:0x55b31a2bbe58] <int> 
    ## │                 └─freq = [51:0x55b31a292278] <dbl> 
    ## ├─matrix = █ [52:0x55b31a292198] <named list> 
    ## │          ├─Q6 = █ [53:0x55b31a2bbd68] <df[,4]> 
    ## │          │      ├─dim2 = [54:0x55b31a2b4238] <chr> 
    ## │          │      ├─Students in paraprofessional roles = [55:0x55b31a2b41f8] <dbl> 
    ## │          │      ├─Students in administrative roles = [56:0x55b31a2b41b8] <dbl> 
    ## │          │      └─Students in "hybrid" roles (e.g., student workers have both paraprofessional and administrative duties) = [57:0x55b31a2b4178] <dbl> 
    ## │          ├─Q8 = █ [58:0x55b31a2aaf58] <df[,15]> 
    ## │          │      ├─dim2 = [59:0x55b31a2bbcc8] <chr> 
    ## │          │      ├─Student Counseling/Advising = [60:0x55b31a2bbc78] <dbl> 
    ## │          │      ├─Health Professions Advising = [61:0x55b31a2bbc28] <dbl> 
    ## │          │      ├─Alumni Counseling/Advising = [62:0x55b31a2bbbd8] <dbl> 
    ## │          │      ├─Fellowship Advising = [63:0x55b31a2bbb88] <dbl> 
    ## │          │      ├─Pre-Law Advising = [64:0x55b31a2bbb38] <dbl> 
    ## │          │      ├─Program/Event Planning = [65:0x55b31a2bbae8] <dbl> 
    ## │          │      ├─Marketing/Communications = [66:0x55b31a2bba98] <dbl> 
    ## │          │      ├─Employer Relations = [67:0x55b31a2bba48] <dbl> 
    ## │          │      ├─Internship Funding = [68:0x55b31a2bb9f8] <dbl> 
    ## │          │      ├─Office Management/Front Desk = [69:0x55b31a2bb9a8] <dbl> 
    ## │          │      ├─Supervision of Professional Staff = [70:0x55b31a2bb958] <dbl> 
    ## │          │      ├─Budget Management = [71:0x55b31a2bb908] <dbl> 
    ## │          │      ├─Technology Management = [72:0x55b31a2bb8b8] <dbl> 
    ## │          │      └─Assessment (Data, Outcomes, Program) = [73:0x55b31a2bb868] <dbl> 
    ## │          ├─Q36 = █ [74:0x55b31a292128] <df[,7]> 
    ## │          │       ├─dim2 = [75:0x55b31a2b4138] <chr> 
    ## │          │       ├─Number of career fairs offered on-campus or only for students at your institution (not including grad/prof school fairs) = [76:0x55b31a2b40f8] <dbl> 
    ## │          │       ├─Number of information sessions offered by employers (coordinated by your office) = [77:0x55b31a2b40b8] <dbl> 
    ## │          │       ├─Number of interviews conducted on-campus or virtual interviews coordinated by your office (total number, not unique students) *record interviews affiliated with consortia/off-campus events below = [78:0x55b31a2b4078] <dbl> 
    ## │          │       ├─Number of interviews conducted through consortia/off-campus events (total number, not unique students) = [79:0x55b31a2b4038] <dbl> 
    ## │          │       ├─Number of career "treks" (immersion trips lasting at least one day) = [80:0x55b31a2b3ff8] <dbl> 
    ## │          │       └─Number of job shadows (total number, not unique students) = [81:0x55b31a2b3fb8] <dbl> 
    ## │          ├─Q37 = █ [82:0x55b31a292048] <df[,5]> 
    ## │          │       ├─dim2 = [83:0x55b31a2b3f78] <chr> 
    ## │          │       ├─Number of employers who attended career fairs offered on-campus or only for students at your institution (not including graduate/professional school fairs) = [84:0x55b31a2b3f38] <dbl> 
    ## │          │       ├─Number of employers who offered information sessions coordinated by your office = [85:0x55b31a2b3ef8] <dbl> 
    ## │          │       ├─Number of employers who conducted interviews on-campus or virtual interviews coordinated by your office = [86:0x55b31a2b3eb8] <dbl> 
    ## │          │       └─Number of employers who conducted interviews through consortia/off-campus events = [87:0x55b31a2b3e78] <dbl> 
    ## │          ├─Q20 = █ [88:0x55b31a291f68] <df[,7]> 
    ## │          │       ├─dim2 = [89:0x55b31a2b3e38] <chr> 
    ## │          │       ├─# appointments with first-year students by professional staff = [90:0x55b31a2b3df8] <dbl> 
    ## │          │       ├─# appointments with sophomore students by professional staff = [91:0x55b31a2b3db8] <dbl> 
    ## │          │       ├─# appointments with junior students by professional staff = [92:0x55b31a2b3d78] <dbl> 
    ## │          │       ├─# appointments with senior students by professional staff = [93:0x55b31a2b3d38] <dbl> 
    ## │          │       ├─TOTAL #  appointments with students by professional staff = [94:0x55b31a2b3cf8] <dbl> 
    ## │          │       └─# appointments with alumni by professional staff = [95:0x55b31a2b3cb8] <dbl> 
    ## │          ├─Q21 = █ [96:0x55b31a291e88] <df[,6]> 
    ## │          │       ├─dim2 = [97:0x55b31a2bb818] <chr> 
    ## │          │       ├─First-Year = [98:0x55b31a2bb7c8] <dbl> 
    ## │          │       ├─Sophomore = [99:0x55b31a2bb778] <dbl> 
    ## │          │       ├─Junior = [100:0x55b31a2bb728] <dbl> 
    ## │          │       ├─Senior = [101:0x55b31a2bb6d8] <dbl> 
    ## │          │       └─TOTAL (all classes) = [102:0x55b31a2bb688] <dbl> 
    ## │          └─Q24 = █ [103:0x55b31a2bb638] <df[,4]> 
    ## │                  ├─dim2 = [104:0x55b31a2bb5e8] <chr> 
    ## │                  ├─Income from endowed funds = [105:0x55b31a2bb598] <dbl> 
    ## │                  ├─Expendable gifts = [106:0x55b31a2bb548] <dbl> 
    ## │                  └─Other = [107:0x55b31a2bb4f8] <dbl> 
    ## ├─continuous = █ [108:0x55b31a2bb458] <named list> 
    ## │              ├─Q7 = █ [109:0x55b31a2b3c78] <tbl_df[,2]> 
    ## │              │      ├─dim2 = [110:0x55b31a291d38] <chr> 
    ## │              │      └─mean = [111:0x55b31a291cc8] <dbl> 
    ## │              ├─Q19 = █ [112:0x55b31a2b3bf8] <tbl_df[,2]> 
    ## │              │       ├─dim1 = [113:0x55b31a2bb3b8] <chr> 
    ## │              │       └─mean = [114:0x55b31a2bb368] <dbl> 
    ## │              ├─Q22 = █ [115:0x55b31a2b3b78] <tbl_df[,2]> 
    ## │              │       ├─dim1 = [116:0x55b31a291c58] <chr> 
    ## │              │       └─mean = [117:0x55b31a291be8] <dbl> 
    ## │              └─Q23 = █ [118:0x55b31a2b3af8] <tbl_df[,2]> 
    ## │                      ├─dim1 = [119:0x55b31a2bb278] <chr> 
    ## │                      └─mean = [120:0x55b31a2bb228] <dbl> 
    ## └─ranking = █ [121:0x55b31a2b9ec8] <named list> 
    ##             └─Q5 = █ [122:0x55b31a2bb138] <tbl_df[,3]> 
    ##                    ├─Question = [123:0x55b31a2aadf8] <chr> 
    ##                    ├─dim1 = [124:0x55b31a2aad48] <chr> 
    ##                    └─ranking_avg = [125:0x55b31a2aac98] <dbl>

Let’s say you wanted to investigate conference attendance rates (Q9).
You would note that Q9 is a multi-response question:

``` r
question_type |> dplyr::filter(unique=="Q9")
```

    ## # A tibble: 1 × 3
    ##   unique q_type Notes                        
    ##   <chr>  <chr>  <chr>                        
    ## 1 Q9     multi  Conferences attended by staff

Next, you would key into the master list in the following order: master
list –&gt; question type –&gt; question. The ‘$’ in the code below are
how R digs into a deeper level of some object, like a list or a
dataframe. Think of it as opening a door into an inner room of a house.

``` r
all_list$multi$Q9
```

    ## # A tibble: 27 × 3
    ##    value                                                                n   freq
    ##    <chr>                                                            <int>  <dbl>
    ##  1 American College Personnel Association (ACPA)                        3 0.0769
    ##  2 Career Leadership Collective                                         3 0.0769
    ##  3 Career Leadership Collective, ASCN, CLASIC                           1 0.0256
    ##  4 CEIA - Cooperative Education & Internship Association                1 0.0256
    ##  5 Delaware Valley Career Planners - a local group                      1 0.0256
    ##  6 Fellowship Advising (e.g., National Association of Fellowships …     6 0.154 
    ##  7 FGLI Consortium                                                      1 0.0256
    ##  8 Health Professions Advising (e.g., National Association of Advi…    19 0.487 
    ##  9 LACN :)                                                              1 0.0256
    ## 10 LACN, Handshake, National Student Employment Association             1 0.0256
    ## # … with 17 more rows

# Report Building

## R Markdown and html rendering

The “docs” directory within “lacn” contains a processed copy of
everything in the main directory. (Quick sidebar: Consider playing
around with deleting the files in the parent “lacn” directory and only
working in the docs directory. I was too nervous to experiment, but I
think that could save you a few headaches; often, I would knit
**index.Rmd** and find I had been editing the “docs” version of my
scripts in the “code” directory, instead of the parent directory
version, which is where my markdown documents “look” to find their
source code.)

There are two key processes: 1) rerunning all scripts that make up the
“project” each time you edit, in order to make your markdown documents
aware of the updates; and 2) knitting **index.Rmd** to update the “docs”
directory. If you don’t knit **index.Rmd**, your updated code will not
get copied to the “docs” directory.

1.  In lacn/code, there is a file called **source.R**. This script
    “sources” (or runs) all the scripts in the code directory, then
    saves the results as something called a workspace image, which is
    just a special file that contains all the objects, datasets, and
    functions that were run in a given session. By saving this workspace
    image, you can now port it around anywhere, and make sure that any
    other document utilizing that code will always have a consistent,
    up-to-date version. To see how this works, take a moment to inspect
    **GeneralReport.Rmd**. In the “setup” chunk toward the top of the
    document:

load(“../lacn.RData”)

The two dots indicate that the “load” command should look in the
relative parent directory (in this case, “lacn”, since the report is
stored in “docs”). This command loads the workspace image that we just
ran with **source.R**. In this way, any change we make to the code will
be acknowledged by the R Markdown file when we knit it.

To run **source.R**, either click the “source” buttton in the top right
of the pane, or open the shell (top menu: *Tools* –&gt; **Shell**) and
run:

RScript code/source.R

2.  Running **index.Rmd** copies all the code in your parent directory
    (“lacn”) into the output directory, which we’ve specified as “docs”
    in \_site.yml. This is an important step in order to keep “docs” in
    sync with “lacn.” But again, play around with only storing your code
    in “docs.” This will probably be much faster and less error-prone.

Finally, knitting! Each time you’ve finished making changes to, say,
**GeneralReport.Rmd**, click the “Knit” button in the top of the pane.
This will process the markdown document and create a formatted html
file. This is the file that should be referenced in \_site.yml when
specifying the contents of the website’s pages.

Once you’re finished knitting, you can then commit your changes using
the following commands in the shell. (Top menu: *Tools* –&gt; *Shell*).

git add &lt;either put file names here, or just “.” to add stage every
modified file&gt;

git commit -m “message describing the changes made”

git push

The push command will prompt you to provide GitHub personal access token
credentials. Visit [this
documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
for more on how to create a GitHub PAT when connecting your RStudio
project to a remote GitHub repository.

## Webpage hosting

This template is ready for web hosting through GitHub Pages, as it
contains \_site.yml, **index.html**, and the output directory “docs,”
which the web hosting software interprets as the place to find all the
files you reference in \_site.yml.

Each time you push a batch of commits to the remote GitHub repository
connected to Pages, GitHub will automatically deploy all your changes.
This typically takes 1-3 minutes. The small green checkmark on header of
the GitHub repository will temporarily turn into a yellow circle while
its processing and deploying the changes.

To adjust website settings, access your GitHub repository, then go to
“Settings.” Under the “Code and Automation” sidebar, click on “Pages.”
Under “Source,” make sure that your site is being built from the same
directory as the **output\_dir** specified in \_site.yml.

Since we’ve set a Bootstrap theme, you can ignore the “Theme Chooser”
section.
