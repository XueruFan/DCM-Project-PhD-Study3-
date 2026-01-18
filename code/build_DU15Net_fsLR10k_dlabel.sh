#!/bin/bash
set -e

# ============================================================
# Build DU15Net fsLR10k dscalar (Workbench 2.0.1)
# ============================================================

ROI_DIR=/Users/xuerufan/DCM-Project-PhD-Study3-/output/ROI_fsLR10k
OUT_DIR=/Users/xuerufan/DCM-Project-PhD-Study3-/output/ROI_fsLR10k
WB=/Applications/workbench/bin_macosxub/wb_command

# ---------- LEFT hemisphere ----------
${WB} -metric-math \
  "round(1*(n1>0) + 2*(n2>0) + 3*(n3>0) + 4*(n4>0) + 5*(n5>0) + \
         6*(n6>0) + 7*(n7>0) + 8*(n8>0) + 9*(n9>0) + 10*(n10>0) + \
         11*(n11>0) + 12*(n12>0) + 13*(n13>0) + 14*(n14>0) + 15*(n15>0))" \
  lh.DU15Net_fsLR10k.func.gii \
  -var n1  ${ROI_DIR}/lh.DU15Net1_fsLR10k.func.gii \
  -var n2  ${ROI_DIR}/lh.DU15Net2_fsLR10k.func.gii \
  -var n3  ${ROI_DIR}/lh.DU15Net3_fsLR10k.func.gii \
  -var n4  ${ROI_DIR}/lh.DU15Net4_fsLR10k.func.gii \
  -var n5  ${ROI_DIR}/lh.DU15Net5_fsLR10k.func.gii \
  -var n6  ${ROI_DIR}/lh.DU15Net6_fsLR10k.func.gii \
  -var n7  ${ROI_DIR}/lh.DU15Net7_fsLR10k.func.gii \
  -var n8  ${ROI_DIR}/lh.DU15Net8_fsLR10k.func.gii \
  -var n9  ${ROI_DIR}/lh.DU15Net9_fsLR10k.func.gii \
  -var n10 ${ROI_DIR}/lh.DU15Net10_fsLR10k.func.gii \
  -var n11 ${ROI_DIR}/lh.DU15Net11_fsLR10k.func.gii \
  -var n12 ${ROI_DIR}/lh.DU15Net12_fsLR10k.func.gii \
  -var n13 ${ROI_DIR}/lh.DU15Net13_fsLR10k.func.gii \
  -var n14 ${ROI_DIR}/lh.DU15Net14_fsLR10k.func.gii \
  -var n15 ${ROI_DIR}/lh.DU15Net15_fsLR10k.func.gii

${WB} -set-structure lh.DU15Net_fsLR10k.func.gii CORTEX_LEFT

# ---------- RIGHT hemisphere ----------
${WB} -metric-math \
  "round(1*(n1>0) + 2*(n2>0) + 3*(n3>0) + 4*(n4>0) + 5*(n5>0) + \
         6*(n6>0) + 7*(n7>0) + 8*(n8>0) + 9*(n9>0) + 10*(n10>0) + \
         11*(n11>0) + 12*(n12>0) + 13*(n13>0) + 14*(n14>0) + 15*(n15>0))" \
  rh.DU15Net_fsLR10k.func.gii \
  -var n1  ${ROI_DIR}/rh.DU15Net1_fsLR10k.func.gii \
  -var n2  ${ROI_DIR}/rh.DU15Net2_fsLR10k.func.gii \
  -var n3  ${ROI_DIR}/rh.DU15Net3_fsLR10k.func.gii \
  -var n4  ${ROI_DIR}/rh.DU15Net4_fsLR10k.func.gii \
  -var n5  ${ROI_DIR}/rh.DU15Net5_fsLR10k.func.gii \
  -var n6  ${ROI_DIR}/rh.DU15Net6_fsLR10k.func.gii \
  -var n7  ${ROI_DIR}/rh.DU15Net7_fsLR10k.func.gii \
  -var n8  ${ROI_DIR}/rh.DU15Net8_fsLR10k.func.gii \
  -var n9  ${ROI_DIR}/rh.DU15Net9_fsLR10k.func.gii \
  -var n10 ${ROI_DIR}/rh.DU15Net10_fsLR10k.func.gii \
  -var n11 ${ROI_DIR}/rh.DU15Net11_fsLR10k.func.gii \
  -var n12 ${ROI_DIR}/rh.DU15Net12_fsLR10k.func.gii \
  -var n13 ${ROI_DIR}/rh.DU15Net13_fsLR10k.func.gii \
  -var n14 ${ROI_DIR}/rh.DU15Net14_fsLR10k.func.gii \
  -var n15 ${ROI_DIR}/rh.DU15Net15_fsLR10k.func.gii

${WB} -set-structure rh.DU15Net_fsLR10k.func.gii CORTEX_RIGHT

# ---------- metric -> dscalar ----------
${WB} -cifti-create-dense-scalar \
  DU15Net_fsLR10k.dscalar.nii \
  -left-metric  lh.DU15Net_fsLR10k.func.gii \
  -right-metric rh.DU15Net_fsLR10k.func.gii

echo "DONE!"