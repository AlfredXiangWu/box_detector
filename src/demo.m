clear all;
clc;

addpath('./util/');

%% box detect and segment
% img_dir = '../data/chinese/';
% save_dir = '../result/chinese/';
% param.wavelet_name = 'db1';
% param.iter = 7;
% param.blank_width = 80;
% 
% res = box_detector(img_dir, param, save_dir);

%% word extract
% img_dir = '../data/exam/';
% save_dir = '../result/exam/';
% param.step = 10;
% 
% res = word_extract( img_dir, param, save_dir );


%% chinese demo
% img_dir = '../data/test/';
% save_dir = '../result/test/';
% 
% param.wavelet_name = 'db1';
% param.thr_word = 0.03;
% param.step = 0;
% 
% res = chinese_exam_crop(img_dir, param, save_dir);

%%
img_dir = '../data/test/';
save_dir = '../result/test/';

param.wavelet_name = 'db1';
param.thr_word = 0.03;
param.step = 0;

res = exam_crop(img_dir, param, save_dir);
