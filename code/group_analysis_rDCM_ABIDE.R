# ============================================================
# ABIDE rDCM group-level analysis
# Subsample: Male participants, AGE_AT_SCAN < 13
# Model: EC ~ DX_GROUP + (1 | site)
# ============================================================

# ----------------------------
# 0. Libraries
# ----------------------------
library(tidyverse)
library(readxl)
library(lme4)
library(lmerTest)
library(broom.mixed)

# ----------------------------
# 1. Paths
# ----------------------------
rdcm_path <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_rDCM_summary.xlsx"
demo_path <- "/Users/xuerufan/DCM-Project-PhD-Study3-/supplement/abide_A_all_240315.csv"
site_dir  <- "/Volumes/Zuolab_XRF/data/abide/sublist"

out_csv   <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_rDCM_group_effects_male_under13.csv"

# ----------------------------
# 2. Read rDCM results
# ----------------------------
rdcm <- read_xlsx(rdcm_path)
rdcm <- rdcm %>%
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
    )
  )

demo <- demo %>%
  mutate(Participant = as.character(Participant))

# ----------------------------
# 4. Build subject → site mapping (merge NYU and NYU2)
# ----------------------------
site_map <- list.files(
  site_dir,
  pattern = "^subjects_.*\\.list$",
  full.names = TRUE
) %>%
  map_dfr(function(f) {
    
    # 从文件名中提取站点名
    site <- basename(f) %>%
      str_remove("^subjects_") %>%
      str_remove("\\.list$") %>%
      toupper()
    
    # 读取被试编号，并统一为字符型、去前导 0
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
  # 只删掉 rdcm 自带的 site（避免 site.x / site.y）
  select(-site) %>%
  
  # 先把人口学信息 join 进来
  left_join(
    demo %>% select(Participant, DX_GROUP, SEX, AGE_AT_SCAN),
    by = c("subject" = "Participant")
  ) %>%
  
  # 再 join 官方 site_map
  left_join(site_map, by = "subject") %>%
  
  # 现在再做筛选
  filter(
    !is.na(DX_GROUP),
    !is.na(SEX),
    !is.na(site),
    AGE_AT_SCAN < 13,
    SEX == "Male"
  )

# ----------------------------
# 6. Sanity checks (recommended)
# ----------------------------
cat("Age summary:\n")
print(summary(data_all$AGE_AT_SCAN))

cat("\nSex:\n")
print(table(data_all$SEX))

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
# 8. Model definition
# ----------------------------
fit_ec <- function(df) {
  m <- lmer(
    EC ~ DX_GROUP + (1 | site),
    data = df,
    REML = FALSE
  )
  broom.mixed::tidy(m, effects = "fixed")
}
# 对某一条特定的有效连接（EC），
# 用线性混合效应模型来检验：
# ASD 与对照组在该连接的平均值上是否存在系统性差异，
# 同时控制不同采集站点之间的基线差异
# 固定效应是dx-group，意思是对该连接，比较 ASD vs Control 的平均 EC 是否不同
# 随机效应(1 | site)意思是允许每一个采集站点有自己的“基线 EC 偏移量”，站点差异被当作随机噪声来源，而不是研究对象
# “在控制站点差异后，是否存在一致的诊断效应？”

# 9. Fit model for all connections
# ----------------------------
results <- data_long %>%
  group_by(connection) %>%
  group_modify(~ fit_ec(.x)) %>%
  ungroup()
# 这一步建模过程中 72% 的连接出现了 singular fit

# ----------------------------
# 10. Extract ASD vs Control effect
# ----------------------------
group_effect <- results %>%
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
# 11. Multiple comparison correction
# ----------------------------
group_effect <- group_effect %>%
  mutate(
    p_fdr = p.adjust(p.value, method = "fdr")
  )

# ----------------------------
# 12. Save results
# ----------------------------
write_csv(group_effect, out_csv)

cat("\nAnalysis finished.\nResults saved to:\n", out_csv, "\n")

# 查看效应量分布
ggplot(group_effect, aes(x = estimate)) +
  geom_histogram(bins = 40, color = "black", fill = "grey80") +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(
    x = "ASD − Control (EC difference)",
    y = "Number of connections"
  ) +
  theme_classic()
# 明显偏离 0 → 分布级效应
# 围绕 0 对称 → 真正的 null
# 长尾 → 少数连接有较大效应，但不稳定


# 方向一致性
n_pos <- sum(group_effect$estimate > 0)
n_neg <- sum(group_effect$estimate < 0)
n_tot <- n_pos + n_neg

n_pos
n_neg

prop_pos <- n_pos / n_tot
prop_neg <- n_neg / n_tot

prop_pos
prop_neg

binom.test(n_pos, n_tot, p = 0.5)

