clear all;
clc;

%% parameters
wavelet_name = 'db1';
iter = 5;
thr = 10;


%% process
img = imread('../data/chinese/201309_yuwen_3.jpg');
% img = imread('../data/chinese/201309_yuwen_2.jpg');
save_dir = '../result/chinese/';
img_name = '201309_yuwen_1.jpg';

[height, width, channel] = size(img);
if channel ~=1
    img = rgb2gray(img);
end
img = im2double(img);

[h, v] = wavelet_transform_2d_n(img, wavelet_name, iter);
h = (h > 0) + (h < 0);
v = (v > 0) + (v < 0);

% get v_idx
fh = imopen(h, ones(1, floor(0.15*width)));
avg_fh_1 = mean(fh, 1);
avg_fh_idx = find(avg_fh_1 < 0.01);
avg_fh_idx_diff = diff(avg_fh_idx);
tmp_idx = find(avg_fh_idx_diff>0.2*width);
v_idx = [];
for i = 1:length(tmp_idx)
    v_idx = [v_idx, [avg_fh_idx(tmp_idx(i)); avg_fh_idx(tmp_idx(i)+1)]];
end



% get h_idx
 h_idx = {};
for num = 1:size(v_idx, 2)
    tmp = zeros(height, 1);
    internal_tmp = v_idx(2, num) - v_idx(1, num);
    for i2 = (v_idx(1, num) + floor(0.2*internal_tmp)):(v_idx(2, num) - floor(0.2*internal_tmp))
        tmp = tmp | fh(:, i2);
    end
    ha = find(tmp==1);
    h_internal = diff(ha);
    idx = find(h_internal > 30);
    h_num = length(idx);
    h_idx_tmp = [];

    for i3 = 1:h_num
        h_idx_tmp = [h_idx_tmp [ha(idx(i3))+5; ha(idx(i3)+1)+5]];
    end
    h_idx{num} = h_idx_tmp;
end

% save
img_name = regexp(img_name, '\.*', 'split');
path = sprintf('%s/', save_dir);
if ~exist(path)
    mkdir(path);
end

count = 1;
for i = 1:size(v_idx, 2) 
    v_start = v_idx(1, i) + 1;
    v_end = v_idx(2, i);
    for j = 1:size(h_idx{i}, 2) 
        h_start = h_idx{i}(1, j) + 1;
        h_end = h_idx{i}(2, j) - 1;              
        
        tmp = img(h_start:h_end, v_start:v_end);
        per = numel(find((tmp>0.8)==0))/(size(tmp, 1)*size(tmp, 2));       
        if per < 0.1
            continue;
        end   
        
        [flag, word_idx] = is_chinese_paper(tmp, 0.03);      
        if flag
            path = sprintf('%s/article/', save_dir);
            if ~exist(path)
                mkdir(path);
            end
            for n = 1:size(word_idx, 2)
                save_patch = tmp(:, word_idx(1, n):word_idx(2, n));
                save_path = sprintf('%s%s_%03d_%03d.jpg', path, img_name{1}, count, n);
                % blank remove
                per = numel(find((save_patch>0.8)==0))/(size(save_patch, 1)*size(save_patch, 2));       
                if per < 0.1
                    continue;
                end   
                save_patch = word_fix(save_patch);
                imwrite(save_patch, save_path);
            end
        else
            path = sprintf('%s/other/', save_dir);
            if ~exist(path)
                mkdir(path);
            end
            save_path = sprintf('%s%s_%03d.jpg', path, img_name{1}, count);
            imwrite(tmp, save_path);
        end
        count = count + 1;            
    end
end
