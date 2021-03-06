## ----package-loading-and-options, warning=FALSE, include=FALSE--------------------------------------------------------------------------------------------------------

## ----load-all-SLobjects, message=FALSE, error=FALSE, warning=FALSE----------------------------------------------------------------------------------------------------
library("cvAUC")
library("conflicted")
library("tidyverse")
library("dplyr")
library("cowplot")
library("ggplot2")
library("vimp")
library("kyotil")
library(gridExtra)
library(cowplot)
library(COVIDcorr)
library(here)
# filter() is used in both dplyr and stats, so need to set the preference to dplyr
conflict_prefer("filter", "dplyr")
conflict_prefer("summarise", "dplyr")
#source(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/cluster_code/define-screens-and-algs.R"))
source(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/cluster_code/utils.R"))
#source("plot_assays.R")
source(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/processingSLresults/make_forest_plot.R"))
method <- "method.CC_nloglik" # since SuperLearner relies on this to be in GlobalEnv
ggplot2::theme_set(theme_cowplot())

load(file = "H:/COVIDcorrSAP/results/SL_estimated_optimal_surrogate/yd57_vaccine_cvaucs.rda")


## ----learner-screens, warning=kable_warnings--------------------------------------------------------------------------------------------------------------------------
caption <- "All learner-screen combinations (14 in total) used as input to the superlearner."

tab <- yd57_vaccine_cvaucs %>%
  filter(!Learner %in% c("SL", "Discrete SL")) %>%
  #filter(!file %in% c("1_only_matvars")) %>%
  select(Learner, Screen) %>%
  mutate(Screen = fct_relevel(Screen, c("all", "glmnet", "univar_logistic_pval",
                                        "highcor_random")),
         Learner = as.factor(Learner),
         Learner = fct_relevel(Learner, c("SL.mean","SL.glm","SL.bayesglm", "SL.glm.interaction", 
                                          "SL.glmnet","SL.gam", # "SL.gam.2", "SL.gam.3", "SL.gam.4", "SL.nnet", "SL.ksvm", "SL.polymars", 
                                          "SL.xgboost", "SL.cforest"))) %>%
  arrange(Learner, Screen) %>% 
  distinct(Learner, Screen) %>%
  rename("Screen*" = Screen) 

tab %>% write.csv(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/learner-screens.csv"))

## ----All 14 variable sets --------------------------------------------------------------------------------------------------------------------
caption <- "The 14 variable sets on which an estimated optimal surrogate was built."

tab <- data.frame(`Variable Set Name` = c("1_baselineRiskFactors", 
                                          "2_varset_bAbSpike", "3_varset_bAbRBD", "4_varset_pnabID50", "5_varset_pnabID80",
                                          "6_varset_lnabID50", "7_varset_lnabID80", "8_varset_bAb_pnabID50", "9_varset_bAb_pnabID80", 
                                          "10_varset_bAb_lnabID50", "11_varset_bAb_lnabID80", "12_varset_bAb_combScores", "13_varset_allMarkers",
                                          "14_varset_allMarkers_combScores"),
                  `Variables included in the set` = c("Baseline risk factors only (Reference model)",
                                                      "Baseline risk factors + bAb anti-Spike markers",
                                                      "Baseline risk factors + bAb anti-RBD markers",
                                                      "Baseline risk factors + p-nAb ID50 markers",
                                                      "Baseline risk factors + p-nAb ID80 markers",
                                                      "Baseline risk factors + l-nAb ID50 markers",
                                                      "Baseline risk factors + l-nAb ID80 markers",
                                                      "Baseline risk factors + bAb markers + p-nAb ID50 markers",
                                                      "Baseline risk factors + bAb markers + p-nAb ID80 markers",
                                                      "Baseline risk factors + bAb markers + l-nAb ID50 markers",
                                                      "Baseline risk factors + bAb markers + l-nAb ID80 markers",
                                                      "Baseline risk factors + bAb markers + combination scores across the six markers",
                                                      "Baseline risk factors + all individual markers",
                                                      "Baseline risk factors + all individual markers + all combination scores (Full model)"))

tab %>% write.csv(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/varsets.csv"))


## ----SLperformance-vacc-y1, warning=kable_warnings--------------------------------------------------------------------------------------------------------------------
caption <- "Performance of Superlearner and the top-performing learner-screen combinations (CV-AUCs with 95\\% CIs) for each of the 14 variable sets using vaccine group and yD57 as outcome."

sl.perf <- yd57_vaccine_cvaucs %>%
  filter(Learner == "SL") %>%
  mutate(AUCstr = ifelse(AUC %in% tail(sort(AUC), 1), paste0(AUCstr, "*"), AUCstr)) %>% 
  select(varset, AUCstr) %>%
  mutate(varset = fct_relevel(varset,
                            c("1_baselineRiskFactors", 
                              "2_varset_bAbSpike", "3_varset_bAbRBD", "4_varset_pnabID50", "5_varset_pnabID80",
                              "6_varset_lnabID50", "7_varset_lnabID80", "8_varset_bAb_pnabID50", "9_varset_bAb_pnabID80", 
                              "10_varset_bAb_lnabID50", "11_varset_bAb_lnabID80", "12_varset_bAb_combScores", "13_varset_allMarkers",
                              "14_varset_allMarkers_combScores"))) %>%
  arrange(varset) %>%
  rename(`SL CV-AUC (95% CI)` = AUCstr,
         `Variable set` = varset) 


top.algo <- yd57_vaccine_cvaucs %>%
  filter(AUCstr != "none") %>%
  group_by(varset) %>%
  filter(AUC == max(AUC)) %>%
  ungroup() %>%
  mutate(AUCstr = ifelse(AUC %in% tail(sort(AUC), 1), paste0(AUCstr, "*"), AUCstr)) %>% 
  select(varset, Learner, Screen, AUCstr) %>%
  rename(`Variable set` = varset,
         `CV-AUC (95% CI)` = AUCstr) 

# top.algo_none <- yd57_vaccine_cvaucs %>%
#   filter(AUCstr == "none") %>%
#   distinct(file, .keep_all = TRUE) %>%
#   ungroup() %>%
#   select(file, Learner, Screen, AUCstr) %>%
#   rename(`Variable set` = file,
#          `CV-AUC (95% CI)` = AUCstr) 

top.algo <- top.algo %>% #bind_rows(top.algo, top.algo_none) %>%
  mutate(`Variable set` = fct_relevel(`Variable set`,
                              c("1_baselineRiskFactors", 
                                "2_varset_bAbSpike", "3_varset_bAbRBD", "4_varset_pnabID50", "5_varset_pnabID80",
                                "6_varset_lnabID50", "7_varset_lnabID80", "8_varset_bAb_pnabID50", "9_varset_bAb_pnabID80", 
                                "10_varset_bAb_lnabID50", "11_varset_bAb_lnabID80", "12_varset_bAb_combScores", "13_varset_allMarkers",
                                "14_varset_allMarkers_combScores"))) %>%
  arrange(`Variable set`) 

tab <- top.algo %>% full_join(sl.perf, by = "Variable set") %>%
  select(`Variable set`, `SL CV-AUC (95% CI)`, everything()) 

tab %>% write.csv(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/SLperformance-vacc-yd57.csv"))

##############################################################################################################################
##############################################################################################################################
# Forest plots for risk_placebo model
############## y1 endpoint ########################
# placebo group
png(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/optsurrogate_vacc_cvaucs.png"), width=1000, height=1100)
top_learner <- make_forest_plot(yd57_vaccine_cvaucs %>% filter(varset=="2_varset_bAbSpike"))
grid.arrange(top_learner$top_learner_nms_plot, top_learner$top_learner_plot, ncol=2)
dev.off()


#################################################################################################################################
#################################################################################################################################
# For yd57 vaccine and selected variable set,  plot ROCcurve and pred.Prob with SL, Discrete SL and top 2 best-performing individual Learners
yd57_vaccine_cvaucs_2varset <- yd57_vaccine_cvaucs %>% 
  mutate(Screen_fromRun = sapply(strsplit(Screen_fromRun,"_All"), `[`, 1),
         Screen_fromRun = paste0(Screen_fromRun, "_", Learner, "_All"),
         Screen_fromRun = ifelse(Learner == "SL", "Super Learner",
                                 ifelse(Learner == "Discrete SL", "Discrete SL", Screen_fromRun))) %>%
  mutate(file = varset) %>%
  filter(varset == "2_varset_bAbSpike")
top2_vacc <- bind_rows(yd57_vaccine_cvaucs_2varset %>% arrange(-AUC) %>% dplyr::slice(1:2),
                       yd57_vaccine_cvaucs_2varset %>% filter(Learner=="SL"),
                       yd57_vaccine_cvaucs_2varset %>% filter(Learner=="Discrete SL"))

load(file = paste0("H:/COVIDcorrSAP/results/SL_estimated_optimal_surrogate/cvsl_optsurrog_cvfits_EventIndPrimaryD57_vacc_", top2_vacc$file[2], ".rda"))
pred <- get_cv_predictions(cvfits[[1]], cvaucDAT = yd57_vaccine_cvaucs_2varset, varSet = top2_vacc$file[2])

# plot ROC curve
png(file = paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/ROCcurve_yd57_vacc_", top2_vacc$file[2], ".png"), width=900, height=600)
p1 <- plot_roc_curves(pred, cvaucDAT = top2_vacc, varSet = top2_vacc$file[2]) 
print(p1)
dev.off()

png(file = paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/predProb_yd57_vacc_", top2_vacc$file[2], ".png"), width=900, height=600)
#p1 <- plot_roc_curves(pred, cvaucDAT = y2_vaccine, varSet = top2_vacc$file[1]) 
p2 <- plot_predicted_probabilities(pred)
# vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
# grid.newpage()
# pushViewport(viewport(layout = grid.layout(8, 4)))
# print(p1, vp = vplayout(1:4, 2:3))
# print(p2, vp = vplayout(5:8, 1:4))
print(p2)
dev.off()
# rm(cvfits, pred, p1, p2)
rm(cvfits, pred, p1, p2)
# #################################################################################################################################
# # get predictions on vaccine group
# load(file = paste0("H:/COVIDcorrSAP/results/SL_estimated_optimal_surrogate/score_vaccineGroup.rda")) 
# score_vaccine <- as.data.frame(score_vaccine)
# vacc <- bind_cols(COVIDcorr::dat.mock %>%
#                     filter(Perprotocol == 1) %>%
#                     filter(Trt == 1),
#                   score_vaccine) %>%
#   rename(pred = V1) %>%
#   # add AUC
#   mutate(AUCchar = format(round(fast.auc(pred, EventIndPrimaryD57),3), nsmall=3),
#          risk_score = log(pred/(1-pred))) 
# 
# write.csv(vacc,"H:/COVIDcorrSAP/results/SL_estimated_optimal_surrogate/vaccine_dat_with_predictions.csv", row.names = FALSE)
# #################################################################################################################################
#################################################################################################################################

# Find predictors selected in the Superlearner run 
# Placebo group
load(file = paste0("H:/COVIDcorrSAP/results/SL_estimated_optimal_surrogate/optsurrog_slfits_yd57_vacc_2_varset_bAbSpike.rda"))
slfits$coef %>% 
  as.data.frame() %>%
  tibble::rownames_to_column(var = "Learners") %>%
  rename(`Weights` = ".") %>%
  write.csv(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/SL_weights.csv"))

library(glmnet)
#coef(slfits[["fitLibrary"]]$screen_glmnet_plus_exposure_SL.xgboost_All$object) %>%
slfits[["fitLibrary"]]$screen_glmnet_plus_exposure_SL.xgboost_All$which_vars %>%
  as.matrix() %>%
  as.data.frame() %>%
  tibble::rownames_to_column(var = "Predictors") %>%
  select(Predictors) %>%
  write.csv(paste0(here(), "/correlates_report/SL_estimated_optimal_surrogate/output/xgboost_covars.csv"))

rm(slfits)

# 
# # y2 endpoint
# # Vaccine group
# load("N:/cavd/Objective 4/GH-VAP/ID33-Wilson/Data/adata/objective3/results_with_allvars_n6/y2_vaccine/SLFITS/fits_y2_vaccine_4_varset_EIA.log10d14overd0.rda")
# fit[["fitLibrary"]]$screen_all_plus_exposure_SL.glm_All$object$coefficients %>% 
#   as.data.frame() %>%
#   tibble::rownames_to_column(var = "Predictors") %>%
#   rename(`Coefficient` = ".") %>%
#   mutate(`Odds Ratio` = exp(`Coefficient`)) %>%
#   write.csv(paste0(here(), "/correlates_report/objective3/input/coef_y2_vaccine_4_varset_EIA.log10d14overd0.csv"))
# rm(fit)
# # load("N:/cavd/Objective 4/GH-VAP/ID33-Wilson/Data/adata/objective3/results_with_allvars_n6/y2_vaccine/SLFITS/fits_y2_vaccine_22_varset_EIA_all4.rda")
# # fit[["fitLibrary"]]$screen_all_plus_exposure_SL.glm_All$object$coefficients %>% 
# #   as.data.frame() %>%
# #   tibble::rownames_to_column(var = "Predictors") %>%
# #   rename(`Coefficient` = ".") %>%
# #   mutate(`Odds Ratio` = exp(`Coefficient`)) %>%
# #   write.csv("H:/RSVcorrelatesAnalysis/correlates_report/objective3/input/coef_y2_vaccine_22_varset_EIA_all4.csv")
# # rm(fit)
# # Placebo group
# load("N:/cavd/Objective 4/GH-VAP/ID33-Wilson/Data/adata/objective3/results_with_allvars_n6/y2_placebo/SLFITS/fits_y2_placebo_23_varset_PCA_all4.rda")
# fit[["fitLibrary"]]$screen_glmnet_plus_exposure_SL.bayesglm_All$object$coefficients %>% 
#   as.data.frame() %>%
#   tibble::rownames_to_column(var = "Predictors") %>%
#   rename(`Coefficient` = ".") %>%
#   mutate(`Odds Ratio` = exp(`Coefficient`)) %>%
#   write.csv(paste0(here(), "/correlates_report/objective3/input/coef_y2_placebo_23_varset_PCA_all4.csv"))
# rm(fit)
# # load("N:/cavd/Objective 4/GH-VAP/ID33-Wilson/Data/adata/objective3/results_with_allvars_n6/y2_placebo/SLFITS/fits_y2_placebo_8_varset_PCA.log10d14overd0.rda")
# # library(glmnet)
# # coef(fit[["fitLibrary"]]$screen_glmnet_plus_exposure_SL.glmnet_All$object) %>% 
# #   as.matrix() %>% 
# #   as.data.frame() %>%
# #   tibble::rownames_to_column(var = "Predictors") %>%
# #   rename(`Coefficient` = "1") %>%
# #   mutate(`Odds Ratio` = exp(`Coefficient`)) %>%
# #   write.csv("H:/RSVcorrelatesAnalysis/correlates_report/objective3/input/coef_y2_placebo_8_varset_PCA.log10d14overd0.csv")
# # rm(fit)
# 
# ######################################################################################################################
# ######################################################################################################################
# # Appendix section 
# # Make forest plots 
# varset = relevel_fileColumn(y1_vaccine) %>% .$file %>% unique()
# # print(varset) # make sure order is correct
# 
# for (i in c("y1", "y2")) {
#   for (j in 1:29) { 
#     # print(i)
#     # print(j)
#     # print(match(j, varset))
#     if(i == "y1"){
#       top <- make_forest_plot_2panels(y1_vaccine %>% filter(file == varset[j]),
#                                       y1_placebo %>% filter(file == varset[j]))
#       png(paste0(here(), "/correlates_report/objective3/input/y1_forest_varset_", j, ".png"), width=1000, height=1100)
#       print(plot_grid(top$top_learner_nms_plot_vacc, top$top_learner_plot_vacc, top$top_learner_nms_plot_plac, top$top_learner_plot_plac,
#                 align = "none",
#                 ncol=4,
#                 rel_widths = c(1/2, 1/2, 1/5, 1/2)))
#       dev.off()
#     }
#     if(i == "y2"){
#       top <- make_forest_plot_2panels(y2_vaccine %>% filter(file == varset[j]),
#                                       y2_placebo %>% filter(file == varset[j]))
#       png(paste0(here(), "/correlates_report/objective3/input/y2_forest_varset_", j, ".png"), width=1000, height=1100)
#       print(plot_grid(top$top_learner_nms_plot_vacc, top$top_learner_plot_vacc, top$top_learner_nms_plot_plac, top$top_learner_plot_plac,
#                 align = "none",
#                 ncol=4,
#                 rel_widths = c(1/2, 1/2, 1/5, 1/2)))
#       dev.off()
#     }
#   }
# }
# 
# ######################################################################################################################
#   

