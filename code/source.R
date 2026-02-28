
# clear global env
rm(list = ls())

# specify code location (relative to working directory)
code_location <- "code"

# source basic cleaning and set-up
source(file.path(code_location, "1_read_data.R"))
source(file.path(code_location, "2_clean.R"))
source(file.path(code_location, "3_functions.R"))

source(file.path(code_location, "99_processing_functions.R"))
source(file.path(code_location, "99_processing.R"))


# source viz set-up scripts
source(file.path(code_location, "4_viz_intro.R"))
source(file.path(code_location, "5_viz_reporting.R"))
source(file.path(code_location, "6_viz_services.R"))

source(file.path(code_location, "7_viz_employer.R"))
source(file.path(code_location, "8_viz_engagement.R"))
source(file.path(code_location, "9_viz_budget.R"))



# save global environment in project directory
save.image(file = "lacn.RData")

