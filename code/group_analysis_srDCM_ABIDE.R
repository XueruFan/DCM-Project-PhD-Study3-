# ============================================================
# ABIDE sparsity rDCM group-level analysis
# Subsample: Male participants, AGE_AT_SCAN < 13
# Analysis: Connection presence (density) comparison
# ============================================================
rm(list = ls())
# ----------------------------
# 0. Libraries
# ----------------------------
library(tidyverse)
library(readxl)
library(lme4)
library(broom.mixed)

# ----------------------------
# 1. Paths
# ----------------------------
rdcm_path <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_srDCM_summary.xlsx"
demo_path <- "/Users/xuerufan/DCM-Project-PhD-Study3-/supplement/abide_A_all_240315.csv"
site_dir  <- "/Volumes/Zuolab_XRF/data/abide/sublist"


######################## male under 13 ##############################################

out_csv   <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_srDCM_density_male_under13.csv"

# ----------------------------
# 2. Read rDCM results
# ----------------------------
rdcm <- read_xlsx(rdcm_path) %>%
  mutate(subject = as.character(as.integer(subject)))

# ----------------------------
# 3. Read demographic information
# ----------------------------
demo <- read_csv(demo_path) %>%
  select(
    Participant,
    DX_GROUP,
    AGE_AT_SCAN,
    SEX
  ) %>%
  mutate(
    DX_GROUP = factor(
      DX_GROUP,
      levels = c(2, 1),
      labels = c("Control", "ASD")
    ),
    SEX = factor(
      SEX,
      levels = c(1, 2),
      labels = c("Male", "Female")
    ),
    Participant = as.character(Participant)
  )

# ----------------------------
# 4. Build subject → site mapping
# ----------------------------
site_map <- list.files(
  site_dir,
  pattern = "^subjects_.*\\.list$",
  full.names = TRUE
) %>%
  map_dfr(function(f) {
    
    site <- basename(f) %>%
      str_remove("^subjects_") %>%
      str_remove("\\.list$") %>%
      toupper()
    
    subjects <- read_lines(f) %>%
      as.character() %>%
      as.integer() %>%
      as.character()
    
    tibble(
      subject = subjects,
      site = site
    )
  })

# ----------------------------
# 5. Merge all information
# ----------------------------
data_all <- rdcm %>%
  select(-site) %>%   # 防止 site.x / site.y
  left_join(
    demo %>% select(Participant, DX_GROUP, SEX, AGE_AT_SCAN),
    by = c("subject" = "Participant")
  ) %>%
  left_join(site_map, by = "subject") %>%
  filter(
    !is.na(DX_GROUP),
    !is.na(SEX),
    !is.na(site),
    AGE_AT_SCAN < 13,
    SEX == "Male"
  )

# ----------------------------
# 6. Sanity checks
# ----------------------------
cat("Age summary:\n")
print(summary(data_all$AGE_AT_SCAN))

cat("\nDiagnosis:\n")
print(table(data_all$DX_GROUP))

cat("\nSites:\n")
print(table(data_all$site))

# ----------------------------
# 7. Wide → Long
# ----------------------------
data_long <- data_all %>%
  pivot_longer(
    cols = starts_with("EC_"),
    names_to = "connection",
    values_to = "EC"
  )

# ----------------------------
# 8. Define connection presence
# ----------------------------
# In sparsity rDCM:
# EC == 0  -> connection absent
# EC != 0  -> connection present
data_long <- data_long %>%
  mutate(
    present = if_else(EC != 0, 1L, 0L)
  )

# ----------------------------
# 9. Descriptive: presence proportion
# ----------------------------
density_table <- data_long %>%
  group_by(connection, DX_GROUP) %>%
  summarise(
    n_present = sum(present),
    n_total   = n(),
    proportion = n_present / n_total,
    .groups = "drop"
  )

# ----------------------------
# 10. Group comparison (Fisher exact test)
# ----------------------------
density_test <- data_long %>%
  group_by(connection) %>%
  summarise(
    n_ASD_present     = sum(present[DX_GROUP == "ASD"]),
    n_ASD_absent      = sum(DX_GROUP == "ASD") - n_ASD_present,
    n_Control_present = sum(present[DX_GROUP == "Control"]),
    n_Control_absent  = sum(DX_GROUP == "Control") - n_Control_present,
    
    p_value = fisher.test(
      matrix(
        c(
          n_ASD_present,
          n_ASD_absent,
          n_Control_present,
          n_Control_absent
        ),
        nrow = 2,
        byrow = TRUE
      )
    )$p.value,
    
    .groups = "drop"
  )

# ----------------------------
# 11. Multiple comparison correction
# ----------------------------
density_test <- density_test %>%
  mutate(
    p_fdr = p.adjust(p_value, method = "fdr")
  ) %>%
  arrange(p_value)

# ----------------------------
# 12. Merge proportions for interpretation
# ----------------------------
density_results <- density_test %>%
  left_join(
    density_table %>%
      select(connection, DX_GROUP, proportion) %>%
      pivot_wider(
        names_from = DX_GROUP,
        values_from = proportion,
        names_prefix = "prop_"
      ),
    by = "connection"
  )

# ----------------------------
# 13. Save results
# ----------------------------
write_csv(density_results, out_csv)

cat("\nAnalysis finished.\nResults saved to:\n", out_csv, "\n")


######################## all ##############################################

# ============================================================
# ABIDE sparsity rDCM group-level analysis
# Analysis: Connection presence (logistic mixed-effects model)
# ============================================================

rm(list = ls())

# ----------------------------
# 0. Libraries
# ----------------------------
library(tidyverse)
library(readxl)
library(lme4)
library(broom.mixed)

# ----------------------------
# 1. Paths
# ----------------------------
rdcm_path <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_srDCM_summary.xlsx"
demo_path <- "/Users/xuerufan/DCM-Project-PhD-Study3-/supplement/abide_A_all_240315.csv"
site_dir  <- "/Volumes/Zuolab_XRF/data/abide/sublist"

out_csv   <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_srDCM_logistic.csv"

# ----------------------------
# 2. Read rDCM results
# ----------------------------
rdcm <- read_xlsx(rdcm_path) %>%
  mutate(subject = as.character(as.integer(subject)))

# ----------------------------
# 3. Read demographic information
# ----------------------------
demo <- read_csv(demo_path, show_col_types = FALSE) %>%
  select(
    Participant,
    DX_GROUP,
    AGE_AT_SCAN,
    SEX
  ) %>%
  mutate(
    DX_GROUP = factor(DX_GROUP, levels = c(2, 1), labels = c("Control", "ASD")),
    SEX      = factor(SEX,      levels = c(1, 2), labels = c("Male", "Female")),
    Participant = as.character(Participant)
  )

# ----------------------------
# 4. Build subject → site mapping
# ----------------------------
site_map <- list.files(
  site_dir,
  pattern = "^subjects_.*\\.list$",
  full.names = TRUE
) %>%
  map_dfr(function(f) {
    
    site <- basename(f) %>%
      str_remove("^subjects_") %>%
      str_remove("\\.list$") %>%
      toupper()
    
    subjects <- read_lines(f) %>%
      as.character() %>%
      as.integer() %>%
      as.character()
    
    tibble(subject = subjects, site = site)
  })

# ----------------------------
# 5. Merge all information
# ----------------------------
data_all <- rdcm %>%
  select(-site) %>%
  left_join(
    demo %>% select(Participant, DX_GROUP, AGE_AT_SCAN, SEX),
    by = c("subject" = "Participant")
  ) %>%
  left_join(site_map, by = "subject") %>%
  filter(
    !is.na(DX_GROUP),
    !is.na(AGE_AT_SCAN),
    !is.na(SEX),
    !is.na(site)
  )

# ----------------------------
# 6. Wide → Long
# ----------------------------
data_long <- data_all %>%
  pivot_longer(
    cols = starts_with("EC_"),
    names_to = "connection",
    values_to = "EC"
  ) %>%
  mutate(
    present = if_else(EC != 0, 1L, 0L),
    AGE_c   = AGE_AT_SCAN - mean(AGE_AT_SCAN, na.rm = TRUE)
  )

# ----------------------------
# 7. Remove connections with constant response
# ----------------------------
data_long_var <- data_long %>%
  group_by(connection) %>%
  filter(n_distinct(present) > 1) %>%
  ungroup()

cat("Connections before filtering:", n_distinct(data_long$connection), "\n")
cat("Connections after filtering :", n_distinct(data_long_var$connection), "\n")

# ----------------------------
# 8. Logistic mixed-effects model
# ----------------------------
fit_presence <- function(df) {
  m <- glmer(
    present ~ DX_GROUP + AGE_c + SEX + (1 | site),
    data = df,
    family = binomial,
    control = glmerControl(
      optimizer = "bobyqa",
      optCtrl = list(maxfun = 2e5)
    )
  )
  broom.mixed::tidy(m, effects = "fixed")
}

presence_results <- data_long_var %>%
  group_by(connection) %>%
  group_modify(~ fit_presence(.x)) %>%
  ungroup()

# ----------------------------
# 9. Extract ASD vs Control effect
# ----------------------------
group_effect <- presence_results %>%
  filter(term == "DX_GROUPASD") %>%
  select(
    connection,
    estimate,
    std.error,
    statistic,
    p.value
  ) %>%
  arrange(p.value)

# ----------------------------
# 10. Multiple comparison correction
# ----------------------------
group_effect <- group_effect %>%
  mutate(p_fdr = p.adjust(p.value, method = "fdr"))

# ----------------------------
# 11. Save results
# ----------------------------
write_csv(group_effect, out_csv)

cat("\nAnalysis finished.\nResults saved to:\n", out_csv, "\n")
