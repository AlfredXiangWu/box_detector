clear all;
clc;


%% box detect and segment
% img_dir = '../data/temp/';
% save_dir = '../result/temp/';
% 
% param.wavelet_name = 'db1';
% param.iter = 7;
% param.blank_width = 80;
% 
% res = box_detector(img_dir, param, save_dir);

%% word extract
img_dir = '../data/foxconn/';
save_dir = '../result/foxconn/';

param.step = 10;

res = word_extract( img_dir, param, save_dir );