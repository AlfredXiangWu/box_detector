function res = exam_crop(img_dir, param, save_dir)
     %% parameters
    wavelet_name = param.wavelet_name;
    thr_word = param.thr_word;
    step = param.step;
     
    %% process
    
    subdir =dir(img_dir);
%     parfor iter = 1:length(subdir)
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
        

        
        % wavelet transform
        [h, v] = wavelet_transform_2d_n(img, wavelet_name, 5);
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

        for i = 1:size(v_idx, 2) 
            v_start = v_idx(1, i) + 1;
            v_end = v_idx(2, i);
            for j = 1:size(h_idx{i}, 2) 
                h_start = max(h_idx{i}(1, j) -1, 1);
                h_end = min(h_idx{i}(2, j) +2, height);              

                tmp = img(h_start:h_end, v_start:v_end);
%                 [flag, word_idx] = is_chinese_paper(tmp, thr_word);
%                 if flag == 1 && size(word_idx, 2) >= 18
%                     break;
%                 end
            end
        end
        
        count = 1;
        for i = 1:size(v_idx, 2) 
            v_start = v_idx(1, i) + 1;
            v_end = v_idx(2, i);
            for j = 1:size(h_idx{i}, 2) 
                h_start = max(h_idx{i}(1, j) -1, 1);
                h_end = min(h_idx{i}(2, j) +2, height);              

                tmp = img(h_start:h_end, v_start:v_end);
                per = numel(find((tmp>0.8)==0))/(size(tmp, 1)*size(tmp, 2));       
                if per < 0.1
                    continue;
                end   
                
%                 [flag, ~] = is_chinese_paper(tmp, thr_word); 
                [flag, word_idx] = is_chinese_paper(tmp, thr_word);
                % line remove
                min_peak_dist = size(tmp, 1) - 4;               
                tmp = line_remove((tmp > 0.6), min_peak_dist);               
                
                if flag
                    path = sprintf('%s/%s/', save_dir, img_name{1});
                    if ~exist(path)
                        mkdir(path);
                    end
                    for n = 1:size(word_idx, 2)
                        tmp_v_start = max(word_idx(1, n), 1);
                        tmp_v_end = min(word_idx(2, n), size(tmp, 2));
                        save_patch = tmp(:, tmp_v_start:tmp_v_end);           
                        save_path = sprintf('%s%s_%03d_%03d.png', path, img_name{1}, tmp_v_start, h_start);                      
                        % blank remove
                        per = numel(find((save_patch>0.8)==0))/(size(save_patch, 1)*size(save_patch, 2));   
                        save_patch = word_fix(save_patch);
                        if per < 0.1                           
                            continue;
                        end
                        
                        save_patch = word_alignment(save_patch, step);
                        imwrite(save_patch, save_path);
                    end
                else
                    path = sprintf('%s/other/', save_dir);
                    if ~exist(path)
                        mkdir(path);
                    end
                    save_path = sprintf('%s%s_%03d.png', path, img_name{1}, count);
                    imwrite(tmp, save_path);
                end
                
                count = count + 1;            
            end
        end
    end
    res = 1;
end