function res = word_extract( img_dir, param, save_dir )
    
    %% parameter
    step = param.step;
    
    %% process
    subdir =dir(img_dir);
    for iter = 1:length(subdir)
        if subdir(iter).isdir
            continue;
        end
        fprintf('[%.2f%%] %s\n', 100*iter/length(subdir), subdir(iter).name);
   
        % load image
        img_name = subdir(iter).name;
        img_path = sprintf('%s%s', img_dir, img_name);
        img = imread(img_path);
        [height, width, channel] = size(img);
        if channel ~=1
            img = rgb2gray(img);
        end
        img = im2double(img);
        
%         img = imrotate(img, 180);
        
        [h, v] = wavelet_transform_2d_n(img, 'db1', 5);
        h = (h > 0) + (h < 0);
        v = (v > 0) + (v < 0);
        
        % crop word
        fh = imopen(h, ones(1, floor(0.2*width)));
        fv = imopen(v, ones(floor(0.16*height), 1));

        temp = zeros(length((1+step):(height-step)), 1);
        for i = floor(0.4*width):floor(0.5*width)
            temp = temp | fh((1+step):(height-step), i);
        end
        h_tmp = find(temp==1);
        h_tmp_diff = diff(h_tmp);
        h_diff_idx = find(h_tmp_diff > 60);
        h_idx = [];
        for i = 1:size(h_diff_idx, 1)
            h_idx = [h_idx [h_tmp(h_diff_idx(i)); h_tmp(h_diff_idx(i)+1)]];
        end

        temp = zeros(1, length((1+step):(width-step)));
        for i = floor(0.1*height):floor(0.9*height);
            temp = temp | fv(i, (1+step):(width-step));
        end

        w_tmp = find(temp==1);
        w_tmp_diff = diff(w_tmp);
        w_diff_idx = find(w_tmp_diff > 60);
        w_idx = [];
        for i = 1:size(w_diff_idx, 2)
            w_idx = [w_idx [w_tmp(w_diff_idx(i)); w_tmp(w_diff_idx(i)+1)]];
        end

        % word cropped, binary and save
        img_name = regexp(img_name, '\.*', 'split');
        path = sprintf('%s', save_dir);
        if ~exist(path)
            mkdir(path);
        end
        
        count = 1;
        for i = 1:size(h_idx, 2) - 1
            for j = 1:size(w_idx, 2) - 1
                hstart = max(h_idx(1, i) + 10, 1);
                hend = min(h_idx(2, i) + 15, height);
                wstart = max(w_idx(1, j) + 10, 1);
                wend = min(w_idx(2, j) + 15, width);
                tmp = img(hstart:hend, wstart:wend);
%                 tmp = (tmp > 0.8); 
                save_patch = word_alignment(tmp, step);
                
                % error detector
                per = numel(find((save_patch>0.8)==0))/(size(tmp, 1)*size(tmp, 2));       
                save_path = sprintf('%s/%s_%03d.jpg', path, img_name{1}, count);
                if per < 0.01
                    continue;
                end   
                imwrite(save_patch, save_path);
                count = count + 1;
            end
        end
    end
    
    res = 1;
end


