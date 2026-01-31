# ============================================================
# Figure 1: rDCM 网络 × 网络 组间效应矩阵
# 最终稳定版：
# - 输出 600 dpi PNG（避免 PDF + 中文字体问题）
# - 中文标题 / 坐标轴 / 图例
# - 功能系统分块排序
# - y 轴反转（阅读友好）
# - 使用未校正 p 值进行高亮（仅视觉强调）
# ============================================================

rm(list = ls())

# ----------------------------
# 0. Libraries
# ----------------------------
library(tidyverse)
library(readr)
library(stringr)
library(ggplot2)

# ----------------------------
# 1. Input / Output paths
# ----------------------------
in_csv  <- "/Volumes/Zuolab_XRF/data/abide/stats/ABIDE_rDCM_group_effects.csv"
out_png <- "/Volumes/Zuolab_XRF/data/abide/figures/ABIDE_rDCM_group_effects.png"

# ----------------------------
# 2. Network lookup table
# ----------------------------
net_lut <- tibble(
  index = 1:15,
  abbr = c(
    "VIS-P","CG-OP","DN-B","SMOT-B","AUD","PM-PPr",
    "dATN-B","SMOT-A","LANG","FPN-B","FPN-A",
    "dATN-A","VIS-C","SAL/PMN","DN-A"
  )
)

# ----------------------------
# 3. Functional system order
# ----------------------------
net_order_blocks <- c(
  "VIS-P","VIS-C",
  "AUD",
  "SMOT-B","SMOT-A","PM-PPr",
  "dATN-B","dATN-A",
  "CG-OP","SAL/PMN",
  "FPN-B","FPN-A",
  "LANG",
  "DN-B","DN-A"
)

# ----------------------------
# 4. Read results
# ----------------------------
df <- read_csv(in_csv, show_col_types = FALSE)

# ----------------------------
# 5. Parse EC indices
# ----------------------------
df_long <- df %>%
  mutate(
    source = as.integer(str_extract(connection, "(?<=EC_)\\d+")),
    target = as.integer(str_extract(connection, "(?<=_)\\d+$"))
  )

# ----------------------------
# 6. Add network labels
# ----------------------------
df_long <- df_long %>%
  left_join(net_lut, by = c("source" = "index")) %>%
  rename(source_abbr = abbr) %>%
  left_join(net_lut, by = c("target" = "index")) %>%
  rename(target_abbr = abbr)

# ----------------------------
# 7. Factor ordering + significance
# ----------------------------
df_long <- df_long %>%
  mutate(
    source_f = factor(source_abbr, levels = net_order_blocks),
    target_f = factor(target_abbr, levels = rev(net_order_blocks)),
    
    # 使用未校正 p 值进行视觉高亮
    sig_raw  = p.value < 0.05,
    alpha_v  = if_else(sig_raw, 1.0, 0.35)
  )

# ----------------------------
# 8. Plot
# ----------------------------
p <- ggplot(df_long, aes(x = source_f, y = target_f)) +
  
  geom_tile(
    aes(fill = estimate, alpha = alpha_v),
    color = "grey85",
    linewidth = 0.3
  ) +
  
  geom_point(
    data = subset(df_long, sig_raw),
    shape = 21,
    size = 2.2,
    stroke = 0.6,
    fill = NA,
    color = "black"
  ) +
  
  scale_fill_gradient2(
    low = "#2b6cb0",
    mid = "white",
    high = "#c53030",
    midpoint = 0,
    name = expression(beta~"(ASD − 对照组)")
  ) +
  
  scale_alpha_identity() +
  coord_fixed() +
  
  labs(
    title = "无稀疏性rDCM：网络间有效连接的组间差异",
    subtitle = "列表示源网络（Source），行表示目标网络（Target）",
    x = "源网络",
    y = "目标网络"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x    = element_text(angle = 45, hjust = 1),
    panel.grid    = element_blank(),
    plot.title    = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "right"
  )

# ----------------------------
# 9. Save as high-resolution PNG
# ----------------------------
ggsave(
  filename = out_png,
  plot = p,
  width = 10,
  height = 9,
  dpi = 600
)

cat("Figure successfully saved to:\n", out_png, "\n")
