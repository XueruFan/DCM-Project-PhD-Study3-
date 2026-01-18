# ============================================================
# Plot DU15 networks (all ROIs together) on fsaverage5 surface
# Output:
#   LH lateral, LH medial, RH lateral, RH medial
#
# Author: Xueru Fan
# ============================================================

import os
import numpy as np
import nibabel as nib
from nilearn import plotting, datasets
from matplotlib.colors import ListedColormap
import matplotlib.pyplot as plt
from PIL import Image


ROI_DIR = "/Users/xuerufan/DCM-Project-PhD-Study3-/output/ROI_fsaverage5"
OUT_DIR = "/Users/xuerufan/DCM-Project-PhD-Study3-/visual"
os.makedirs(OUT_DIR, exist_ok=True)

# ------------------------------------------------------------
# DU15 network RGB table (index: 1–15)
# values normalized to 0–1
# ------------------------------------------------------------
DU15_COLORS = {
    0: (170, 170, 170),  # background
    1: (170, 70, 125),
    2: (184, 89, 251),
    3: (205, 61, 77),
    4: (27, 179, 242),
    5: (231, 215, 165),
    6: (66, 231, 206),
    7: (98, 206, 61),
    8: (73, 145, 175),
    9: (11, 47, 255),
    10: (228, 228, 0),
    11: (240, 147, 33),
    12: (10, 112, 33),
    13: (119, 17, 133),
    14: (254, 188, 235),
    15: (100, 49, 73),
}

# Normalize RGB to [0,1]
colors = [tuple(np.array(DU15_COLORS[i]) / 255) for i in range(16)]
cmap = ListedColormap(colors)


fsavg = datasets.fetch_surf_fsaverage(mesh="fsaverage5")

# ------------------------------------------------------------
# Helper function: build label map for one hemisphere
# ------------------------------------------------------------
from nilearn import surface

def build_label_map(hemi):
    """
    Build a single label map for all DU15 networks
    Ensures correct 1D vertex alignment for fsaverage5
    """

    # ---- load surface to get vertex count ----
    if hemi == "lh":
        coords, _ = surface.load_surf_mesh(fsavg.pial_left)
    else:
        coords, _ = surface.load_surf_mesh(fsavg.pial_right)

    n_vertices = coords.shape[0]
    label_map = np.zeros(n_vertices, dtype=int)

    for net in range(1, 16):
        roi_file = os.path.join(
            ROI_DIR, f"{hemi}.DU15Net{net}_fsaverage5.mgz"
        )

        img = nib.load(roi_file)

        # ---- CRITICAL: force 1D vertex vector ----
        data = np.asarray(img.get_fdata()).reshape(-1)

        if data.shape[0] != n_vertices:
            raise ValueError(
                f"Vertex count mismatch in {roi_file}: "
                f"{data.shape[0]} vs {n_vertices}"
            )

        label_map[data > 0.5] = net

    return label_map


# ------------------------------------------------------------
# 裁剪图片尺寸
# ------------------------------------------------------------

def crop_to_brain(png_file, bg_thresh=245, padding=5):
    """
    Crop white margins based on image content.
    
    Parameters
    ----------
    png_file : str
        Path to PNG image
    bg_thresh : int
        Threshold to consider a pixel as background (0–255)
    padding : int
        Extra pixels to keep around brain
    """
    img = Image.open(png_file).convert("RGB")
    arr = np.array(img)

    # background mask: nearly white
    bg = np.all(arr > bg_thresh, axis=2)

    # find non-background rows/cols
    rows = np.where(~bg.all(axis=1))[0]
    cols = np.where(~bg.all(axis=0))[0]

    if len(rows) == 0 or len(cols) == 0:
        return  # safety

    rmin = max(rows.min() - padding, 0)
    rmax = min(rows.max() + padding, arr.shape[0])
    cmin = max(cols.min() - padding, 0)
    cmax = min(cols.max() + padding, arr.shape[1])

    cropped = img.crop((cmin, rmin, cmax, rmax))
    cropped.save(png_file)


# ------------------------------------------------------------
# Build label maps
# ------------------------------------------------------------
lh_labels = build_label_map("lh")
rh_labels = build_label_map("rh")

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------
surf_bg = "#DDDDDD"  # light gray background

views = [
    "lateral",
    "medial",
    "anterior",
    "posterior",
    "dorsal",
    "ventral",
]

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------
for view in views:
    out_file = os.path.join(
        OUT_DIR, f"DU15_fsaverage5_LH_{view}.png")

    fig = plt.figure(figsize=(4, 4))   # 控制画布大小
    ax = fig.add_subplot(111, projection="3d")

    plotting.plot_surf_roi(
        fsavg.infl_left,
        roi_map=lh_labels,
        bg_map=fsavg.sulc_left,
        hemi="left",
        view=view,
        cmap=cmap,
        bg_on_data=True,
        alpha=0.2,
        colorbar=False,
        title=None,
        axes=ax,
        figure=fig
    )

    fig.savefig(out_file, dpi=300, bbox_inches="tight", pad_inches=0)
    plt.close(fig)
    
    crop_to_brain(out_file)



for view in views:
    out_file = os.path.join(
        OUT_DIR, f"DU15_fsaverage5_RH_{view}.png")

    fig = plt.figure(figsize=(4, 4))   # 控制画布大小
    ax = fig.add_subplot(111, projection="3d")

    plotting.plot_surf_roi(
        fsavg.infl_right,
        roi_map=rh_labels,
        bg_map=fsavg.sulc_right,
        hemi="right",
        view=view,
        cmap=cmap,
        bg_on_data=True,
        alpha=0.2,
        colorbar=False,
        title=None,
        axes=ax,
        figure=fig
    )

    fig.savefig(out_file, dpi=300, bbox_inches="tight", pad_inches=0)
    plt.close(fig)
    
    crop_to_brain(out_file)


plotting.show()
