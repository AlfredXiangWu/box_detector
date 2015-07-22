clear all;
clc;

%% pre-processing
% img = imread('../data/chinese.bin.1.remove_red.png');
img = imread('../data/chinese.bin.remove_red.png');
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
fh = imopen(h, ones(1,150));
figure, imshow(fh);

fv = imopen(v, ones(150, 1));
figure, imshow(fv);

% f = fh + fv;
% figure, imshow(f);

%% crop box 
% fv
tmp = zeros(1, width);
for j = 1:height
    tmp = tmp | fv(j, :);
end
a = find(tmp==1);
internal = diff(a);
idx = find(internal > 0.2*width);
subplot(131), imshow(img(:, a(idx(1)):a(idx(2))));
subplot(132), imshow(img(:, a(idx(2)):a(idx(3))));
subplot(133), imshow(img(:, a(idx(3)):a(end)));
% fh
tmp = zeros(height, 1);
for i = 1:width
    tmp = tmp | fh(:, i);
end


