%% main_run.m
% NLOS Assignment 4

clear; clc;

cfg = default_cfg();

% Choose one:
% "transients", "z_usaf", "bunny", "attenuation", "phasor"
cfg.section = "attenuation";

switch cfg.section
    case "transients"
        section1_transients(cfg);
    case "z_usaf"
        section2_backprojection_z_usaf(cfg);
    case "bunny"
        section3_bunny_compare(cfg);
    case "attenuation"
        section4_attenuation(cfg);
    case "phasor"
        section5_phasor_sweep(cfg);
    otherwise
        error('Seccion no reconocida: %s', cfg.section);
end
