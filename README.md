# DCM-Project[PhD Study3]

## Step 1: 提取ROI

fsLR-32k ROI（MATLAB 顶点索引）
↓
export_ROI_wb.m
↓
.func.gii（fsLR-32k）
↓
resample_fsLR32k_to_fsaverage164k.sh
↓
.func.gii（fsaverage-164k）
↓
resample_fsaverage164_to_fsaverage5.sh
↓
.mgh（fsaverage5）
↓
ROI 时间序列提取
