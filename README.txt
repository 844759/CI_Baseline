NLOS modular skeleton for Assignment 4
=====================================

This folder splits the original single-file workflow into sections so you can run
only what you need while tuning parameters.

Suggested use
-------------
1) Put all .m files in one folder.
2) Keep the .mat datasets either:
   - in the same folder, or
   - in a subfolder called "datasets".
3) Open `main_run.m` in MATLAB.
4) Change:
      cfg.section = "phasor";
   to whichever section you want.
5) Run `main_run`.

Available sections
------------------
- "transients"   : x-t / y-t slices
- "z_usaf"       : backprojection sweeps for Z and usaf
- "bunny"        : confocal vs non-confocal bunny
- "attenuation"  : attenuation compensation examples
- "phasor"       : phasor / Morlet sweep for bunny confocal

Why this version is useful
--------------------------
The phasor result you showed is diffuse, so `section5_phasor_sweep.m` already
runs a small parameter sweep instead of a single hard-coded setting.

Main files
----------
- main_run.m
- default_cfg.m
- section1_transients.m
- section2_backprojection_z_usaf.m
- section3_bunny_compare.m
- section4_attenuation.m
- section5_phasor_sweep.m

Shared utilities
----------------
- load_nlos_dataset.m
- visualize_transient_slices.m
- nlos_backprojection.m
- apply_volume_filter.m
- render_volume_views.m
- save_projection.m
- front_projection.m
- morlet_filter_temporal.m
- estimate_wall_spacing.m
- ensure_dir.m

Notes
-----
- This is a practical skeleton intended to be easy to iterate on.
- The phasor section is where you will most likely keep tuning parameters.
- If bunny still looks too diffuse, first check the projection axis and then
  widen/narrow the phasor parameters in default_cfg.m.
