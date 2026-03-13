## Introduction

```
This guide is intended to describe the workflow to create dashboards for the yearly
LACN project. We use RStudio & Google Sheets for this project. I will be using the
desktop version of RStudio for faster local development without any interruptions, but the
Rstudio hosted by the stolaf servers works just as well. You can install the latest version
of R & Rstudio on your machine by following the instructions on this link.
```
```
To understand each of the R files we use in more detail, please refer to the README in
the github repository. The end goal is to create HTML reports for all institutions in LACN
as well as a general summary report.
```
```
Here are some examples from previous years:
● General Report
● Report for St. Olaf College
```
### Setting up GIT

```
Git is distributed version control system used to track changes in files over time,
enabling teams to collaborate on projects and manage code history efficiently. If you are
on a Mac, then git should be pre-installed on your system. However, on windows you will
need to set it up manually. You can install the correct version of git using the link here.
Note that if you are working with git for the first time, you will need to create a github
account and set up an SSH key that links your machine to your account, so you can
clone a remote repository without any problem– here’s how you do that correctly.
```
```
Once you have git and your SSH key correctly set up, you should go ahead and fork the
previous year’s repository from Nate’s github. A git fork is when you copy someone
else's repository into your own GitHub (or GitLab) account so you can work on it
independently. Here’s a short video I created to show you should fork from Nate’s github.
Note that last year’s repository was forked from my account, so I can’t fork it back again,
but you should see your account name under the owner option. Also, the project
currently just has one main branch (so the ‘Copy the main branch only’ option should not
matter as of now). However,it is good practice to make your own branch and merge to
main after finalizing everything. This will be especially useful if you make substantial
changes to the project. More info on branches here.
```
```
After forking, the next step is to clone the fork on your account using SSH to your
machine:
```

Then work on your own repository without syncing changes back to Nate’s repository
Deploy GitHub Pages on your own GitHub for testing purposes. The workflow is going to
look something like this:
● Make local changes to the files to accommodate for new data
● Test it to see if it works
● Stage the changed files (using RStudio’s console window)
○ git add <changed files>
● Commit and add message for your new push
○ git commit -m <describe the changes made succinctly>
● Pull/Push to the appropriate branch
○ git pull origin <branch name (main if you did not create a new branch)>
(Note that you technically don’t need this step because you’re the only
one working on this project, but it’s considered good practice)
○ git push origin <branch name>

```
At the end:
● Duplicate your current repository into a new blank repository using link below
○ https://stackoverflow.com/questions/6613166/how-to-duplicate-a-git-repos
itory-without-forking
● Nate forks new repository copy to house that year’s report
● Deploy GitHub pages in Nate’s new repository
○ Settings → pages → branch to main → Save
■ Wait a few minutes, then use github.io link + file path
■ https://njacobi29.github.io/lacn2023/docs/custom/StOlafCollege.ht
ml
■ https://njacobi29.github.io/lacn2023/docs/
```

# Reading Data & Processing

```
The first step is to read-in the raw data and create an intermediate document called the
response_key, which is used to specify the question types and to define other
descriptors for the R code.
```
```
The raw data from data is a wide csv, containing each question from the survey as
columns. The file may be named differently when you receive it, but I think it is a good
idea to standardize it. I like the format:
OpsSurveyRawDataMM.DD.YY.csv (with MM.DD.YY) being the time
when the data was extracted.
```
```
The first piece of code you will use is 1_read_data.R inside the code directory. This
code does some preliminary data cleaning. I recommend running this file in chunks to
understand what’s going on. Exercise more precaution if the survey has changed from
last year to avoid wrong columns being deleted. We need to create an intermediate
google subsheet called response_key_YY , which requires some manual cleaning. To
send data to Sheets using your st olaf email, you will have to give authorization to
Tidyverse API. There are explicit instructions in the code. In the google sheet, you will
have two sub-sheets: progress (containing question type) and response_key_YY
(containing different descriptors for the R code). Cleaning the response key manually
will involve making sure that all the column names match up exactly with the previous
year:
```
```
Question, main, sub1, sub2, Description, Notes, dim1, dim2, dim.
```
```
Doing this will help you avoid errors that are minor but hard to trace back. Some
additional tips::
● The Notes column is not directly used by the code. It is there for your own
reference.
● The dim1, dim2, dim3 columns, given that the questions have not changed, need
to be the same as last year.
● If there are any changes to the survey, please review the survey carefully to
understand. If there are new questions, you will need to categorize them
accordingly in the progress tab. Read the github readme to understand the
question types: matrix, text, single, multi, etc. In case of a new question type, you
will need to make adjustments to the file 99_processing_functions.R to be able
to handle the new changes and create new viz.
● If there are minimal changes to the survey, your job will be relatively easy.
However, any kind of change will introduce what I call “offset errors”, which can
take time to debug. This is due to wrong columns being selected or trying to
```

access columns that are no longer there. Try to be more careful in those
scenarios

Next, we use **2_clean.R** to create a list of tibbles ( **question_list** ), one for each
institution in the survey. Note that **question_type** is the same as the progress tab
in google sheets. List of all the R files that need to run (including the code for
reading and cleaning) is present (in the correct order) in **source.R**. Ideally, just
running that file should be enough, but it will be hard to debug if you encounter
an error. Therefore, I suggest doing each run separately and fixing whatever bug
you encounter in steps. The source file also creates and saves an _R image,_
which makes the files and functions readily available to the R Markdown files
inside the docs directory. If you manage to run all the files in **source.R** without
passing any errors, the next step is to knit the R Markdown files inside docs:
**GeneralReport.Rmd** & **customtemplate.Rmd**.


