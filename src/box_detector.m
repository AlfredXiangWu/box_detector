function res = box_detector(img_dir, param, save_dir)

    %% log
    clk = clock();
    log_fn = sprintf('fa2_%4d%02d%02d%02d%02d%02d.log', [clk(1:5) floor(clk(6))]);
    log_fid = fopen(log_fn, 'w+');
    
    %% parameters
    wavelet_name = param.wavelet_name;
    iter = param.iter;
    pad_v = param.pad_v;
    pad_h = param.pad_h;
     

    %% process
    subdir =dir(img_dir);
    for i = 1:length(subdir)
        if subdir(i).isdir
            continue;
        end
        fprintf('[%.2f%%] %s\n', 100*i/length(subdir), subdir(i).name);
   
        % load image
        img_name = subdir(i).name;
        img_path = sprintf('%s%s', img_dir, img_name);
        img = imread(img_path);
        [height, width, channel] = size(img);
        if channel ~=1
            img = rgb2gray(img);
        end
        img = im2double(img);
        
        % wavelet transform
        [h, v] = wavelet_transform_2d_n(img, wavelet_name, iter);
        h = (h > 0) + (h < 0);
        v = (v > 0) + (v < 0);
        
        % line detect
        fh = imopen(h, ones(1, floor(0.2*width)));
        fv = imopen(v, ones(floor(0.3*height), 1));
        
        % crop
        % fv
        tmp_fv = zeros(1, width);
        for j = 1:height
               tmp_fv = tmp_fv | fv(j, :);
        end
        va = find(tmp_fv==1);
        v_diff = diff(va);
        idx = find(v_diff > 0.2*width);
        v_num = length(idx);
        v_idx = [];
        for i = 1:v_num
            v_idx = [v_idx va(idx(i))];
        end
        v_idx = [v_idx va(end) - pad_v];
        clear idx;
        
        % fh
        for num = 1:length(v_idx) - 1
            tmp = zeros(height, 1);
            internal_tmp = v_idx(num+1) - v_idx(num);
            for i = (v_idx(num) + floor(0.2*internal_tmp)):(v_idx(num+1) - floor(0.2*internal_tmp))
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
            h_idx_tmp = [h_idx_tmp ha(end) - pad_h];
            h_idx{num} = h_idx_tmp;
        end
        img_name = regexp(img_name, '\.*', 'split');
        path = sprintf('%s%s', save_dir, img_name{1});
        if ~exist(path)
            mkdir(path);
        end
        % save
        count = 1;
        for i = 1:length(v_idx) - 1
            v_start = v_idx(i);
            v_end = v_idx(i+1);
            for j = 1:length(h_idx{i}) - 1
                h_start = h_idx{i}(j);
                h_end = h_idx{i}(j+1);
               
                save_path = sprintf('%s/%s_%03d.jpg', path, img_name{1}, count);
                imwrite(img(h_start:h_end, v_start:v_end), save_path);
                count = count + 1;            
            end
        end
        
        % write log
        fprintf(log_fid, '%s box detect: %d!\n', img_name{1}, count-1);
    end
    
    close(log_fid);
	res = 1;
end

%% wavelet transform
function [h, v] = wavelet_transform_2d_n(signal, wavelet_name, iter)
    [Lo_D,Hi_D] = wfilters(wavelet_name,'d');

    h = signal;
    v = signal;

    for i = 1:iter
        y = conv2(h, Lo_D(:)','same');
        h = conv2(y, Hi_D(:), 'same');
        z = conv2(v, Hi_D(:)','same');
        v = conv2(z, Lo_D(:),'same');
    end
end