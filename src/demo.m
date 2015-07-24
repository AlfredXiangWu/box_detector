clear all;
clc;


%% parameter
img_dir = '../data/scan_image/';
save_dir = '../result/scan_image/';

param.wavelet_name = 'db1';
param.iter = 7;
param.pad_v = 400;
param.pad_h = 300;

res = box_detector(img_dir, param, save_dir);