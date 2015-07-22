clear all;
clc;

%% pre-processing
img = imread('../data/chinese.bin.1.remove_red.png');
img_name = 'chinese.bin.1.remove_red.png';
% img = imread('../data/chinese.bin.remove_red.png');
[height, width, channel] = size(img);

if channel ~= 1
    img = rgb2gray(img);
end

img = im2double(img);
wavelet_name = 'db1';
iter = 5;

%% wavelet transform
[h, v] = wavelet_transform_2d_n(img, wavelet_name, iter);
h = (h > 0) + (h < 0);
% h = h > 0;
v = (v > 0) + (v < 0);
% v = v > 0;
% result = h + v;
% imshow(h);

%% hough transform
% [H, theta, rho]= hough(h,'RhoResolution', 0.5);  
% peak=houghpeaks(H,5); 
% lines=houghlines(h,theta,rho,peak);
% figure,imshow(h,[]),title('Hough Transform Detect Result'),hold on    
% for k=1:length(lines)    
%     xy=[lines(k).point1;lines(k).point2];    
%     plot(xy(:,1),xy(:,2),'LineWidth',4,'Color',[1 .0 .0]);    
% end 
% 
% [H, theta, rho]= hough(v,'RhoResolution', 0.5);  
% peak=houghpeaks(H,5); 
% lines=houghlines(v,theta,rho,peak);
% figure,imshow(v,[]),title('Hough Transform Detect Result'),hold on    
% for k=1:length(lines)    
%     xy=[lines(k).point1;lines(k).point2];    
%     plot(xy(:,1),xy(:,2),'LineWidth',4,'Color',[1 .0 .0]);    
% end 

%% 
fh = imopen(h, ones(1, floor(0.2*width)));
figure, imshow(fh);

fv = imopen(v, ones(floor(0.5*height), 1));
figure, imshow(fv);

% f = fh + fv;
% figure, imshow(f);

%% crop box 
% fv
tmp = zeros(1, width);
for j = 1:height
    tmp = tmp | fv(j, :);
end
va = find(tmp==1);
v_internal = diff(va);
idx = find(v_internal > 0.2*width);
v_num = length(idx);
v_idx = [];

for i = 1:v_num
    v_idx = [v_idx va(idx(i))];
end
v_idx = [v_idx va(end)];

% subplot(131), imshow(img(:, v_idx(1):v_idx(2)));
% subplot(132), imshow(img(:, v_idx(2):v_idx(3)));
% subplot(133), imshow(img(:, v_idx(3):va(end)));
clear idx;

for num = 1:length(v_idx) - 1
    tmp = zeros(height, 1);
    for i = v_idx(num):v_idx(num+1)
        tmp = tmp | fh(:, i);
    end
    ha = find(tmp==1);
    h_internal = diff(ha);
    idx = find(h_internal > 0.2*height);
    h_num = length(idx);
    h_idx_tmp = [];

    for i = 1:h_num
        h_idx_tmp = [h_idx_tmp ha(idx(i))];
    end
    h_idx_tmp = [h_idx_tmp ha(end)];
    h_idx{num} = h_idx_tmp;
end

%% save
count = 1;
for i = 1:length(v_idx) - 1
    v_start = v_idx(i);
    v_end = v_idx(i+1);
    for j = 1:length(h_idx{i}) - 1
        h_start = h_idx{i}(j);
        h_end = h_idx{i}(j+1);
        save_path = sprintf('%s_%d.jpg', img_name, count);
        imwrite(img(h_start:h_end, v_start:v_end), save_path);
        count = count + 1;
    end
end


