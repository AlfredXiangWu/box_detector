clear all;
clc;


%% parameter
img_dir = '../data/scan_image/';
save_dir = '../result/scan_image/';

param.wavelet_name = 'db1';
param.iter = 7;
 param.blank_width = 80;

res = box_detector(img_dir, param, save_dir);