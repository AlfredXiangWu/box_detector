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
        tmp = find(idx_diff > 60);
        for i = 1:length(tmp)
            res = [res [idx(tmp(i));idx(tmp(i)+1)]];
        end
    end   
end