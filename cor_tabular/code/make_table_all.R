##################################################
# obligatory to append to the top of each script #
renv::activate(project = here::here("..")) #
source(here::here("..", "_common.R")) #
##################################################

library(survey)
library(tidyverse)
library(dplyr, warn.conflicts = FALSE)
# Suppress summarise info
options(dplyr.summarise.inform = FALSE)
# For stratum with 1 ppt
options(survey.lonely.psu="adjust")
source(here::here("code", "make_functions.R"))


###################################################
#                  Parameters                     #
###################################################
# To select which tables are included in the report.
# Also to modify the headers and footers for each table.
tlf <-
  list(
    tab_dm_neg = list(
      table_header = "Demographic and Clinical Characteristics at Baseline in 
      the Baseline SARS-CoV-2 Negative Per-Protocol Cohort",
      table_footer = "This table summarizes the random subcohort, which was 
      randomly sampled from the per-protocol cohort. The sampling was 
      stratified by 24 strata defined by enrollment characteristics: Assigned 
      treatment arm $\\\\times$ Baseline SARS-CoV-2 naïve vs. non-naïve status 
      (defined by serostatus and NAAT testing) $\\\\times$ Randomization strata 
      (Age < 65 and at-risk, Age < 65 and not at-risk, Age $\\\\geq 65)\\\\times$ 
      Communities of color (Yes/No) defined by White Non-Hispanic vs. all 
      others (following the primary COVE trial paper).",
      deselect = "subgroup",
      pack_row = "subgroup",
      col1="7cm"
    ),
    
    tab_dm_pos = list(
      table_header = "Demographic and Clinical Characteristics at Baseline in 
      the Baseline SARS-CoV-2 Positive Per-Protocol Cohort",
      table_footer ="This table summarizes the random subcohort, which was 
      randomly sampled from the per-protocol cohort. The sampling was 
      stratified by 24 strata defined by enrollment characteristics: Assigned 
      treatment arm $\\\\times$ Baseline SARS-CoV-2 naïve vs. non-naïve status 
      (defined by serostatus and NAAT testing) $\\\\times$ Randomization strata 
      (Age < 65 and at-risk, Age < 65 and not at-risk, Age $\\\\geq 65)\\\\times$ 
      Communities of color (Yes/No) defined by White Non-Hispanic vs. all 
      others (following the primary COVE trial paper).",
      deselect = "subgroup",
      pack_row = "subgroup",
      col1="7cm"
    ),
    
    tab_strtm = list(
      table_header = "Sample Sizes of Baseline Strata for Correlates of Risk Analysis",
      table_footer = c("Demographic covariate strata:",
                       "1. Age $\\\\geq$ 65 Minority\\\\hspace{81pt}6. Age < 65 At-risk Unknown", 
                       "2. Age $\\\\geq$ 65 Non-Minority\\\\hspace{60pt}7. Age < 65 Not At-risk Minority",
                       "3. Age $\\\\geq$ 65 Unknown\\\\hspace{78pt}8. Age < 65 Not At-risk Non-Minority",
                       "4. Age < 65 At-risk Minority\\\\hspace{48pt}9. Age < 65 Not At-risk Unknown",
                       "5. Age < 65 At-risk Non-Minority",
                       " ",
                       "Minority includes Blacks or African Americans, Hispanics or Latinos, American Indians or 
                       Alaska Natives, Native Hawaiians, and other Pacific Islanders.",
                       "Non-Minority includes all other races with observed race (Asian, Multiracial, White, Other) and observed ethnicity Not Hispanic or Latino.",
                       "Unknown includes unknown, unreported race or ethnicity.",
                       " ",
                       "Cases for Day 29 marker correlates analyses are per-protocol vaccine recipients with the symptomatic 
                       infection COVID-19 primary endpoint diagnosed starting 7 days after the Day 29 study visit. Cases for Day 57 marker 
                       correlates analyses are per-protocol vaccine recipients with the symptomatic infection COVID-19 
                       primary endpoint diagnosed starting 7 days after the Day 57 study visit. 
                       Non-cases are per-protocol participants sampled into the random subcohort 
                       with no COVID primary endpoint up to the time of data cut and no evidence 
                       of SARS-CoV-2 infection up to six days post Day 57 visit.",
                       "The table shows the numbers of cases sampled into the subcohort within baseline covariate strata."),
      deselect = "Arm",
      pack_row = "Arm"
    ),
    
    case_vacc_neg = list(
      table_header = "Antibody levels in the baseline SARS-CoV-2 negative
      per-protocol cohort (vaccine recipients)",
      table_footer =c(
      "Cases for Day 29 marker correlates analyses are baseline negative per-protocol 
      vaccine recipients with the symptomatic infection COVID-19 primary endpoint diagnosed 
      starting 7 days after the Day 29 study visit. Cases for Day 57 marker correlates 
      analyses are baseline negative per-protocol vaccine recipients with the symptomatic 
      infection COVID-19 primary endpoint diagnosed starting 7 days after the Day 57 study visit. ",
      "N is the number of cases sampled into the subcohort within baseline covariate strata.",
      "The denominator in Resp Rate is the number of participants in the whole per-protocol cohort within baseline
covariate strata, calculated using inverse probability weighting."),

      col_name = c("Visit", "Marker", "N", "Resp rate", "GMT/GMC", "N",
                   "Resp rate", "GMT/GMC", "Resp Rate\nDifference", "GMTR/GMCR"),
      header_above1 = c(" "=2, "Cases*" = 3, "Non-Cases/Control" = 3,
                        "Comparison" = 2),
      header_above2 = c(" "=2,
                        "Baseline SARS-CoV-2 Negative Vaccine Recipients" = 8),
      col1="1cm"
    ),
    
    case_vacc_pos = list(
      table_header = "Antibody levels in the baseline SARS-CoV-2 positive
      per-protocol cohort (vaccine recipients)",
      table_footer = c(
      "The SAP does not specify correlates analyses in baseline positive vaccine recipients. 
      This table summarizes descriptively the same information for baseline positive vaccine 
      recipients that was summarized for baseline negative vaccine recipients. 
      Cases for Day 29 markers are baseline positive per-protocol vaccine recipients 
      with the symptomatic infection COVID-19 primary endpoint diagnosed starting 7 days 
      after the Day 29 study visit. Cases for Day 57 markers are baseline positive 
      per-protocol vaccine recipients with the symptomatic infection COVID-19 primary 
      endpoint diagnosed starting 7 days after the Day 57 study visit. Non-cases/Controls 
      are baseline positive per-protocol vaccine recipients sampled into the random subcohort 
      with no COVID-19 endpoint diagnosis by the time of data-cut.",
      "N is the number of cases sampled into the subcohort within baseline covariate strata.",
      "The denominator in Resp Rate is the number of participants in the whole per-protocol cohort within baseline
covariate strata, calculated using inverse probability weighting."),
      col_name = c("Visit", "Marker", "N", "Resp rate", "GMT/GMC", "N",
                   "Resp rate", "GMT/GMC", "Resp Rate\nDifference", "GMTR/GMCR"),
      header_above1 = c(" "=2, "Cases*" = 3, "Non-Cases/Control" = 3, 
                        "Comparison" = 2),
      header_above2 = c(" "=2,
                        "Baseline SARS-CoV-2 Positive Vaccine Recipients" = 8),
      col1="1cm"
    ),
    
    case_plcb_pos = list(
      table_header = "Antibody levels in the baseline SARS-CoV-2 positive
      per-protocol cohort (placebo recipients)",
      table_footer = c(
        "The SAP does not specify correlates analyses in baseline positive placebo recipients.
        This table summarizes descriptively the same information for baseline positive placebo 
        recipients that was summarized for baseline negative and positive vaccine recipients. 
        Cases for Day 29 markers are baseline positive per-protocol placebo recipients with 
        the symptomatic infection COVID-19 primary endpoint diagnosed starting 7 days after 
        the Day 29 study visit. Cases for Day 57 markers are baseline positive per-protocol 
        placebo recipients with the symptomatic infection COVID-19 primary endpoint diagnosed 
        starting 7 days after the Day 57 study visit. Non-cases/Controls are baseline positive 
        per-protocol placebo recipients sampled into the random subcohort with no COVID-19 endpoint 
        diagnosis by the time of data-cut.",
        "N is the number of cases sampled into the subcohort within baseline covariate strata.",
        "The denominator in Resp Rate is the number of participants in the whole per-protocol cohort within baseline
covariate strata, calculated using inverse probability weighting."
        ),
      col_name = c("Visit", "Marker", "N", "Resp rate", "GMT/GMC", "N",
                   "Resp rate", "GMT/GMC", "Resp Rate\nDifference", "GMTR/GMCR"),
      header_above1 = c(" "=2,  "Cases*" = 3, "Non-Cases/Control" = 3,
                        "Comparison" = 2),
      header_above2 = c(" "=2,
                        "Baseline SARS-CoV-2 Positive Placebo Recipients" = 8),
      col1="1cm"
    )
  )



# Depends on the Incoming data
if(include_bindN){
  assays <- c("bindN", assays)
}
labels.time <- labels.time[times]
# hacky fix
labels.assays.short <- labels.assays.short.tabular[assays]

# redefines what is in _common.R to use shorter names
labels.assays.long <- data.frame (purrr::imap_dfc(labels.assays.short, ~ paste0(labels.assays.short[.y], ": ", labels.time)))
rownames(labels.assays.long) <- names(labels.time)

visits <- names(labels.time)[!grepl("Delta", names(labels.time))]
assays_col <- levels(interaction(visits, assays, sep=""))

labels.assays <- expand.grid(
  time = rownames(labels.assays.long),
  marker = colnames(labels.assays.long),
  stringsAsFactors = FALSE
) %>%
  rowwise() %>%
  mutate(
    label.long = labels.assays.long[time, marker],
    label.short = sapply(labels.assays.short, as.character)[marker],
    Marker = strsplit(as.character(label.long), ": ", fixed = T)[[1]][1],
    Visit = strsplit(as.character(label.long), ": ", fixed = T)[[1]][2],
    colname = paste0(time, marker)
  )

resp.lb <- expand.grid(
  time = visits, marker = assays,
  ind = c("Resp", "FR2", "FR4", "2lloq", "4lloq"), stringsAsFactors = F
) %>%
  mutate(Ind = case_when(
    ind == "FR2" ~ "% 2-Fold Rise",
    ind == "FR4" ~ "% 4-Fold Rise",
    ind == "Resp" ~ "Responder",
    ind == "2lloq" ~ "% Greater than 2xLLOQ",
    ind == "4lloq" ~ "% Greater than 4xLLOQ"
  )) 

labels_all <- full_join(labels.assays, resp.lb, by = c("time", "marker")) %>% 
  mutate(mag_cat = colname, resp_cat = paste0(colname, ind))


###################################################
#                Clean the Data                   #
###################################################

### Table 1. Demographics 
# Output: tab_dm
# Select the covariates to be summarised.
# num_v are columns from ds_long;
# cat_v are rows of `subgroup`


# Read in original data
dat <- read.csv(here::here("../data_clean", data_name))

# The stratified random cohort for immunogenicity
ds_s <- dat %>%
  mutate(
    raceC = as.character(race),
    ethnicityC = case_when(EthnicityHispanic==1 ~ "Hispanic or Latino",
                           EthnicityHispanic==0 & EthnicityNotreported==0 & 
                           EthnicityUnknown==0 ~ "Not Hispanic or Latino",
                           EthnicityNotreported==1 | 
                           EthnicityUnknown==1 ~ "Not reported and unknown "),
    RaceEthC = case_when(
      WhiteNonHispanic==1 ~ "White Non-Hispanic ",
      TRUE ~ raceC
    ),
    MinorityC = case_when(
      WhiteNonHispanic == 0 ~ "Communities of Color",
      WhiteNonHispanic == 1 ~ "White Non-Hispanic"
    ),
    HighRiskC = ifelse(HighRiskInd == 1, "At-risk", "Not at-risk"),
    Age65C = ifelse(age.geq.65 == 1, "Age $\\geq$ 65", "Age $<$ 65"),
    SexC = ifelse(Sex == 1, "Female", "Male"),
    AgeRiskC = paste(Age65C, HighRiskC),
    AgeSexC = paste(Age65C, SexC),
    AgeMinorC = ifelse(is.na(MinorityC), NA, paste(Age65C, MinorityC)),
    `Baseline SARS-CoV-2` = factor(ifelse(Bserostatus == 1, "Positive", "Negative"),
                                   levels = c("Negative", "Positive")
    ),
    Arm = factor(ifelse(Trt == 1, "Vaccine", "Placebo"), 
                 levels = c("Vaccine", "Placebo")),
    
    Case.D57 = case_when(
      Perprotocol==1 & EarlyendpointD57==0 & 
        TwophasesampIndD57==1 & EventIndPrimaryD57==1 ~ "Cases", 
      Perprotocol==1 & EarlyendpointD57==0 & 
        TwophasesampIndD57==1 & EventIndPrimaryD1==0 ~ "Non-Cases"),
    
    Case.D29 = case_when(
      Perprotocol==1 & EarlyendpointD29==0 & 
        TwophasesampIndD29==1 & EventIndPrimaryD29==1~"Cases", 
      Perprotocol==1 & EarlyendpointD57==0 & 
        TwophasesampIndD57==1 & EventIndPrimaryD1==0 ~"Non-Cases"),
    
    demo.stratum.ordered=case_when(!is.na(demo.stratum) ~ 
                                   as.numeric(match(demo.stratum.labels[demo.stratum], 
                                         c("Age >= 65, URM", "Age >= 65, White non-Hisp", "Age >= 65, Unknown", 
                                           "Age < 65, At risk, URM", "Age < 65, At risk, White non-Hisp", "Age < 65, At risk, Unknown", 
                                           "Age < 65, Not at risk, URM", "Age < 65, Not at risk, White non-Hisp", "Age < 65, Not at risk, Unknown"))), 
                                   age.geq.65 == 1 ~ 3, 
                                   age.geq.65 == 0 & HighRiskInd==1 ~ 6,
                                   age.geq.65 == 0 & HighRiskInd==0 ~ 9), 
    
    AgeRisk1 = ifelse(Age65C=="Age $<$ 65", AgeRiskC, NA),
    AgeRisk2 = ifelse(Age65C=="Age $\\geq$ 65", AgeRiskC, NA),
    All = "All participants")

# Step2: Responders
# Post baseline visits
ds <- getResponder(ds_s, cutoff.name="lloq", times=grep("Day", times, value=T), 
                   assays=assays, pos.cutoffs = pos.cutoffs)

subgrp <- c(
  All = "All participants", 
  Age65C = "Age",
  BMI="BMI",
  HighRiskC = "Risk for Severe Covid-19",
  AgeRiskC = "Age, Risk for Severe Covid-19",
  AgeRisk1 = "Age $<$ 65, Risk for Severe Covid-19",
  AgeRisk2 = "Age $\\geq$ 65, Risk for Severe Covid-19",
  SexC = "Sex", 
  AgeSexC = "Age, sex",
  ethnicityC = "Hispanic or Latino ethnicity", 
  RaceEthC = "Race",
  MinorityC = "Underrepresented minority status",
  AgeMinorC = "Age, Underrepresented minority status"

)


###################################################
#             Generating the Tables               #
###################################################

num_v1 <- c("Age") # Summaries - Mean & Range
num_v2 <- c("BMI") # Summaries - Mean & St.d
cat_v <- c("Age65C", "SexC", "raceC", "ethnicityC", "HighRiskC", "AgeRiskC", "MinorityC")

ds_long_ttl <- ds %>%
  dplyr::filter(ph2.immuno) %>% 
  bind_rows(mutate(., Arm="Total")) %>% 
  mutate(AgeRiskC = ifelse(grepl("$\\geq$", AgeRiskC, fixed=T), "Age $\\geq$ 65 ", AgeRiskC)) %>% 
  mutate_all(as.character) %>% 
  pivot_longer(all_of(c(num_v1, num_v2, cat_v)), names_to="subgroup", values_to="subgroup_cat")

# Calculate % for categorical covariates
dm_cat <- inner_join(
  ds_long_ttl %>%
    group_by(`Baseline SARS-CoV-2`, Arm, subgroup, subgroup_cat) %>%
    summarise(n = n(), .groups = 'drop'),
  ds_long_ttl %>%
    group_by(`Baseline SARS-CoV-2`, Arm, subgroup) %>%
    summarise(N = n(), .groups = 'drop'),
  by = c("Baseline SARS-CoV-2", "Arm", "subgroup")
) %>%
  mutate(pct = n / N,
         rslt1 = sprintf("%s (%.1f%%)", n, n / N * 100), 
         rslt2 = sprintf("%s/%s = %.1f%%", n, N, n / N * 100)) %>% 
  dplyr::filter(subgroup %in% cat_v) 

# Calculate mean and range for numeric covariates
dm_num <- ds_long_ttl %>%
  dplyr::filter(subgroup %in% c(num_v1, num_v2)) %>% 
  mutate(subgroup_cat=as.numeric(subgroup_cat)) %>%
  group_by(`Baseline SARS-CoV-2`, Arm, subgroup) %>%
  summarise(
    min = min(subgroup_cat, na.rm = T), 
    max = max(subgroup_cat, na.rm = T),
    mean = mean(subgroup_cat, na.rm = T),
    sd = sd(subgroup_cat, na.rm = T), 
    rslt1 = sprintf("%.1f (%.1f, %.1f)", mean, min, max),
    rslt2 = sprintf("%.1f $\\pm$ %.1f", mean, sd),
    N = n(),
    .groups = 'drop'
  ) %>% 
  mutate(subgroup_cat = case_when(subgroup %in% num_v1 ~ "Mean (Range)",
                                  subgroup %in% num_v2 ~ "Mean $\\pm$ SD"),
         subgroup=ifelse(subgroup=="Age", "Age65C", subgroup))

char_lev <- c("Age $<$ 65", "Age $\\geq$ 65", "Mean (Range)","Mean $\\pm$ SD",
              "Female","Male","White","Black or African American",
              "Asian", "American Indian or Alaska Native",
              "Native Hawaiian or Other Pacific Islander", "Multiracial",
              "Other", "Not reported and unknown", 
              "White Non-Hispanic", "Communities of Color",
              "Hispanic or Latino","Not Hispanic or Latino",
              "Not reported and unknown ","At-risk","Not at-risk",
              "Age $<$ 65 At-risk","Age $<$ 65 Not at-risk", "Age $\\geq$ 65 ")

tab_dm <- bind_rows(dm_cat, dm_num) %>%
  mutate(rslt = case_when(subgroup %in% cat_v ~ rslt1,
                          subgroup %in% num_v1 ~ rslt1,
                          subgroup %in% num_v2 ~ rslt2)) %>%
  mutate(subgroup=ifelse(subgroup %in% c("MinorityC", "raceC"), "RaceEthC", subgroup)) %>% 
  dplyr::filter(subgroup_cat %in% char_lev) %>% 
  inner_join(ds_long_ttl %>% 
               distinct(`Baseline SARS-CoV-2`, Arm, Ptid) %>% 
               group_by(`Baseline SARS-CoV-2`, Arm) %>%
               summarise(tot = n()),
             by = c("Baseline SARS-CoV-2", "Arm")) %>% 
  mutate(Arm = paste0(Arm, "\n(N = ", tot, ")"), subgroup=subgrp[subgroup]) %>%
  pivot_wider(c(`Baseline SARS-CoV-2`, Arm, subgroup, subgroup_cat, rslt),
              names_from = Arm, 
              names_sort = T,
              values_from = c(rslt)) %>%
  mutate(Characteristics = factor(subgroup_cat, levels=char_lev),
         subgroup=factor(subgroup, levels=subgrp)) %>%
  arrange(`Baseline SARS-CoV-2`, subgroup, Characteristics)

tab_dm_pos <- tab_dm %>% 
  dplyr::filter(`Baseline SARS-CoV-2` == "Positive") %>% 
  select_if(~ !all(is.na(.))) %>% 
  select_at(c("subgroup", "Characteristics", 
              grep("Vaccine" ,names(.), value = T),
              grep("Placebo" ,names(.), value = T),
              grep("Total" ,names(.), value = T)))

tab_dm_neg <- tab_dm %>% 
  dplyr::filter(`Baseline SARS-CoV-2` == "Negative") %>% 
  select_if(~ !all(is.na(.))) %>% 
  select_at(c("subgroup", "Characteristics", 
              grep("Vaccine" ,names(.), value = T),
              grep("Placebo" ,names(.), value = T),
              grep("Total" ,names(.), value = T)))

print("Done with table 1") 


# Added table: 
demo.ordered <- c("Age >= 65, URM", "Age >= 65, White non-Hisp", "Age >= 65, Unknown", 
                  "Age < 65, At risk, URM", "Age < 65, At risk, White non-Hisp", "Age < 65, At risk, Unknown", 
                  "Age < 65, Not at risk, URM", "Age < 65, Not at risk, White non-Hisp", "Age < 65, Not at risk, Unknown")

tab_strtm <- ds %>% 
  group_by(demo.stratum.ordered, Arm, `Baseline SARS-CoV-2`) %>%
  summarise(`Day 29 Cases`=sum(Case.D29=="Cases", na.rm=T), 
            `Day 57 Cases`=sum(Case.D57=="Cases", na.rm=T), 
            `Non-Cases`=sum(Case.D57=="Non-Cases", na.rm=T)) %>% 
  pivot_longer(cols=c(`Day 29 Cases`,`Day 57 Cases`, `Non-Cases`)) %>% 
  arrange(`Baseline SARS-CoV-2`, demo.stratum.ordered) %>% 
  pivot_wider(id_cols=c(Arm, name), 
              names_from = c(`Baseline SARS-CoV-2`, demo.stratum.ordered), 
              values_from=value) 

tab_strtm_header1 <- c(" "=1, 
                       "Baseline SARS-CoV-2 Negative" = sum(grepl("Negative", names(tab_strtm))), 
                       "Baseline SARS-CoV-2 Positive" = sum(grepl("Positive", names(tab_strtm))))

colnames(tab_strtm) <- gsub("name", " ", colnames(tab_strtm))
colnames(tab_strtm) <- gsub("Negative_", "", colnames(tab_strtm))
colnames(tab_strtm) <- gsub("Positive_", " ", colnames(tab_strtm))

tab_strtm_header2 <- ncol(tab_strtm)-1
names(tab_strtm_header2) <- sprintf("Per-protocol Cases and Non-Cases (Moderna Trial)")
tlf$tab_strtm$header_above1 <- tab_strtm_header1
tlf$tab_strtm$header_above2 <- tab_strtm_header2


# Generate a full table with all the estimates: response rates, GMT, GMTR, etc.
# (Per Peter's email Feb 5, 2021)
# Cases vs Non-cases

ds.D57 <- filter(ds, ph1.D57)
sub.by <- c("Arm", "`Baseline SARS-CoV-2`")
resp.v.57 <- intersect(grep("Resp", names(ds), value = T),
                       grep("57", names(ds), value = T))
gm.v.57 <- intersect(assays_col, grep("57", names(ds), value = T))

subs <- "Case.D57"
comp_i <- c("Cases", "Non-Cases")

rpcnt_case <- get_rr(ds.D57, resp.v.57, subs, sub.by, strata="Wstratum", weights="wt.D57", subset="ph2.D57") 
rgm_case <- get_gm(ds.D57, gm.v.57, subs, sub.by, strata="Wstratum", weights="wt.D57", "ph2.D57") 
rgmt_case <- get_rgmt(ds.D57, gm.v.57, subs, comp_lev=comp_i, sub.by, "Wstratum", "wt.D57", "ph2.D57") 

print("Done with table 2 & 3") 

if(has29){
  ds.D29 <- filter(ds, ph1.D29)
  subs <- "Case.D29"
  comp_i <- c("Cases", "Non-Cases")
  
  resp.v.29 <- intersect(grep("Resp", names(ds), value = T),
                         grep("29", names(ds), value = T))
  gm.v.29 <- intersect(assays_col, grep("29", names(ds), value = T))
  
  rpcnt_case2 <- get_rr(ds.D29, resp.v.29, subs, sub.by, "Wstratum", "wt.D29", "ph2.D29")
  rgm_case2 <- get_gm(ds.D29, gm.v.29, subs, sub.by, "Wstratum", "wt.D29", "ph2.D29")
  rgmt_case2 <- get_rgmt(ds.D29, gm.v.29, subs, comp_lev=comp_i, sub.by, "Wstratum", "wt.D29", "ph2.D29")

  rpcnt_case <- bind_rows(rpcnt_case, rpcnt_case2)
  rgm_case <- bind_rows(rgm_case, rgm_case2)
  rgmt_case <- bind_rows(rgmt_case, rgmt_case2)
  
  print("Done with table 2b & 3b") 
}

rrdiff_case <- rpcnt_case %>% 
  # dplyr::filter(subgroup %in% subs & grepl("Resp",resp_cat)) %>% 
  mutate(groupn = 2-match(Group, comp_i)%%2) %>%
  pivot_wider(id_cols = c(subgroup, `Baseline SARS-CoV-2`, Arm, Visit, Marker, Ind),
              names_from = groupn, values_from = c(response, ci_l, ci_u), names_sep = "") # %>% 

  responseNA <- setdiff(levels(interaction(c("response", "ci_l", "ci_u"), 1:2, sep="")), names(rrdiff_case))
  rrdiff_case[, responseNA] <- NA
  
  rrdiff_case <- rrdiff_case %>% 
    mutate(Estimate = response1-response2,
           ci_l = Estimate-sqrt((response1-ci_l1)^2+(response2-ci_u2)^2),
           ci_u = Estimate+sqrt((response1-ci_u1)^2+(response2-ci_l2)^2),
           rrdiff = ifelse(!is.na(Estimate), 
                           sprintf("%s\n(%s, %s)", round(Estimate, 2), round(ci_l, 2), round(ci_u, 2)),
                           "-")) 
  
print("Done with table6")

tab_case <- full_join(rpcnt_case, rgm_case,
                      by = c("Group", "Arm", "Baseline SARS-CoV-2", 
                             "N", "Marker", "Visit")) %>% 
  pivot_wider(id_cols = c(Arm, `Baseline SARS-CoV-2`, Marker, Visit),
              names_from = Group, 
              values_from = c(N, rslt, `GMT/GMC`)) %>% 
  full_join(rrdiff_case, by = c("Arm", "Baseline SARS-CoV-2", "Marker", "Visit")) %>% 
  full_join(rgmt_case, by = c("Arm", "Baseline SARS-CoV-2", "Marker", "Visit"))

if(length(comp_NA <- setdiff(comp_i, rpcnt_case$Group))!=0){
  tab_case <- tab_case %>% 
    mutate(!!paste0("N_", comp_NA) := 0, 
           !!paste0("rslt_", comp_NA) := "-",
           !!paste0("GMT/GMC_", comp_NA) :="-",
           `Ratios of GMT/GMC`=replace_na(`Ratios of GMT/GMC`, "-"))
}else{
    tab_case <- tab_case %>% 
      mutate_at(vars(starts_with("N_")), replace_na, replace=0) %>% 
      mutate_at(vars(starts_with("rslt_")), replace_na, replace="-") %>% 
      mutate_at(vars(starts_with("GMT/GMC_")), replace_na, replace="-") %>% 
      mutate(`Ratios of GMT/GMC`=replace_na(`Ratios of GMT/GMC`, "-"))
  }

tab_case <- tab_case %>% 
  select(Arm, `Baseline SARS-CoV-2`, Visit, Marker, `N_Cases`, `rslt_Cases`, 
         `GMT/GMC_Cases`, `N_Non-Cases`, `rslt_Non-Cases`, `GMT/GMC_Non-Cases`,  
         rrdiff, `Ratios of GMT/GMC`) %>% 
  arrange(Arm, `Baseline SARS-CoV-2`, Visit) 
  
case_vacc_neg <- tab_case %>% 
  dplyr::filter(Arm == "Vaccine" & `Baseline SARS-CoV-2` == "Negative") %>% 
  select(-c(Arm, `Baseline SARS-CoV-2`))

case_vacc_pos <- tab_case %>% 
  dplyr::filter(Arm == "Vaccine" & `Baseline SARS-CoV-2` == "Positive") %>% 
  select(-c(Arm, `Baseline SARS-CoV-2`))

case_plcb_pos <- tab_case %>% 
  dplyr::filter(Arm == "Placebo" & `Baseline SARS-CoV-2` == "Positive") %>% 
  select(-c(Arm, `Baseline SARS-CoV-2`))

print("Done with all tables") 

save(tlf, tab_dm_neg, tab_dm_pos, tab_strtm, 
     case_vacc_neg, case_vacc_pos, case_plcb_pos,
     file = here::here("output", "Tables.Rdata"))


