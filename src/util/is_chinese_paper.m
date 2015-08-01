function [flag, res] = is_chinese_paper(img, thr)
    res = [];
    [height, width] = size(img);
    avg = mean(img, 1);
    idx = find(avg < thr);
    if numel(idx) < 10
        flag = 0;
        res = [];
    else
        flag = 1;
        idx_diff = diff(idx);
        tmp_idx_diff = idx_diff;
        tmp_idx_diff(find(idx_diff==1)) = [];
        delta = 56;
        tmp = find(idx_diff > 50); % 60 for chinese exam crop
        for i = 1:length(tmp)
%             scale = idx_diff(tmp(i)) / delta;
%             if scale > 1.5
%                 start = idx(tmp(i));
%                 for j = 1:floor(scale)
%                     res = [res [start+(j-1)*(delta+4); start + (j-1)*(delta+4) + delta]];
%                 end
%             else           
                res = [res [idx(tmp(i));idx(tmp(i)+1)]];
%             end
        end

    end   
end