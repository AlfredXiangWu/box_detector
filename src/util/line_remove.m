function output_image = line_remove(input_image, min_peak_dist)
    % ON = 0;
    % OFF = 1;
    
    if numel(input_image) == 0
        output_image = input_image;
        return;
    end
    
    % ???????????????????????????????????????
    if sum(sum(input_image)) < numel(input_image) / 2
        input_image = ~input_image;
    end
    
    % ??????????????????????????????????????????
    input_image(1, :) = ones(1, size(input_image, 2));
    input_image(end, :) = ones(1, size(input_image, 2));
    
%     % ????????????????????????????????????????????????
%     VERTICAL_LINE_RANGE = 100;  % ?????????????????????????????????RANGE?????????
%     PEAK_COEF = 0.5;            % ????????????????????????rows*coef????????????????????????
%     [rows, columns] = size(input_image);
%     if columns > 2 * VERTICAL_LINE_RANGE
%         vertical_project = sum(~input_image, 1);        % ???????????????
%         [~, locs] = findpeaks(vertical_project, 'MinPeakHeight', rows * PEAK_COEF);
%         
%         left_locs = locs(locs <= VERTICAL_LINE_RANGE);  % ?????????????????????
%         if ~isempty(left_locs)
%             rightmost_left_locs = max(left_locs);       % ???????????????????????????????????????
%             while rightmost_left_locs < columns
%                 if vertical_project(rightmost_left_locs) < vertical_project(rightmost_left_locs + 1)
%                     break;
%                 end
%                 rightmost_left_locs = rightmost_left_locs + 1;
%             end
%             if rightmost_left_locs == columns           % ????????????
%                 output_image = input_image;
%                 return;
%             end
%         else
%             rightmost_left_locs = 1;
%         end
%         
%         right_locs = locs(locs > columns - VERTICAL_LINE_RANGE);    % ?????????????????????
%         if ~isempty(right_locs)
%             leftmost_right_locs = min(right_locs);                  % ???????????????????????????????????????
%             while leftmost_right_locs > 1
%                 if vertical_project(leftmost_right_locs) < vertical_project(leftmost_right_locs - 1)
%                     break;
%                 end
%                 leftmost_right_locs = leftmost_right_locs - 1;
%             end
%             if leftmost_right_locs == 1           % ????????????
%                 output_image = input_image;
%                 return;
%             end
%         else
%             leftmost_right_locs = columns;
%         end
%         
%         input_image = input_image(:, rightmost_left_locs : leftmost_right_locs);
%     end
    
    % ??????????????????
    [ ~, theta ] = imdeskew(input_image);
    if theta ~= 0
        input_image = ~imrotate(~input_image, theta, 'bilinear');
    end
    
    % ??????????????????
    origin_image = input_image;
    
    % ????????????????????????????????????????????????
    [rows, columns] = size(input_image);
    horizontal_project = sum(~input_image, 2);
    % figure; bar(1 : rows, horizontal_project);

    % TODO: ????????????????????????????????????
    if max(horizontal_project) < columns * 0.45
        output_image = input_image;
        return;
    end

    PEAK_COEF = 1 / 3;
%     [~, locs] = findpeaks(horizontal_project, 'MinPeakHeight', max(horizontal_project) / PEAK_ARG);
    [~, locs] = findpeaks(horizontal_project, ...
                          'MinPeakHeight', max(horizontal_project) * PEAK_COEF, ...
                          'MinPeakDistance', min_peak_dist);
%     hold on;
%     for i = locs
%         plot(i, horizontal_project(i), 'ro')
%     end
%     hold off;
    % ???????????????????????????????????????
    peak_num = length(locs);
    if peak_num == 0
        output_image = input_image;
        return;
    end

    % ????????????????????????????????????????????????????????????????????????????????????
    height = zeros(peak_num, 1);
    for i = 1 : peak_num       
        if peak_num == 1
            r1 = 1;
            r2 = rows;
        elseif i == 1
            r1 = 1;
            r2 = floor((locs(i) + locs(i + 1)) / 2);
        elseif i == peak_num
            r1 = ceil((locs(peak_num - 1) + locs(peak_num)) / 2);
            r2 = rows;
        else
            r1 = ceil((locs(i - 1) + locs(i)) / 2);
            r2 = floor((locs(i) + locs(i + 1)) / 2);
        end
        middle_image = input_image(r1 : r2, ...
                                   floor(columns / 5) : ceil(columns * 4 / 5));
        vertical_project = sum(~middle_image, 1);
        vertical_project(~vertical_project) = [];
        height(i) = mode(vertical_project);
    end
    % ?????????????????????????????????????????????????????????????????????
    % ??????????????????????????????????????????????????????????????????????????????
    mode_height = mode(height);
    height(height > 2 * mode_height) = mode_height;
    
%     figure;
%     imshow(middle_image);
%     hold on;
%     for i = 1 : length(height)
%         line([1, columns], [locs(i), locs(i)], 'color', 'r');
%     end
%     hold off;

    % ????????????
    % [noline_img1, lbound1, ubound1] = remove_line(middle_image, locs, height, 1);
    % [noline_img2, lbound2, ubound2] = remove_line(middle_image, locs, height, -1);
    % lbound = min(lbound1, lbound2);
    % ubound = max(ubound1, ubound2);
    % noline_img = noline_img1 & noline_img2;
    [noline_image, lbound, ubound] = remove_line(input_image, locs, height, 1);
    input_image = noline_image;
    % figure; imshow(noline_img);
    
    % ????????????
    for i = 1 : peak_num
        restored1_image = restore_line(input_image, lbound(i, :), ubound(i, :), 1);
        restored2_image = restore_line(input_image, lbound(i, :), ubound(i, :), -1);
        restored3_image = restore_uline(input_image, lbound(i, :), ubound(i, :));
        input_image = (restored1_image | restored2_image) & restored3_image;
    end

    % ?????????????????????????????????
    input_image = input_image | origin_image;
    output_image = input_image;

%     imwrite([origin_image, ones(size(input_image, 1), 50), input_image], '1.png');
    
end

function [lbound, ubound] = get_line_width(input_image, r, c)
    ON = 0;
    OFF = 1;

    lbound = r;
    ubound = r;

    if input_image(r, c) == OFF
        return;
    end

    [rows, ~] = size(input_image);
    while lbound >= 1 && input_image(lbound, c) == ON
        lbound = lbound - 1;
    end
    lbound = lbound + 1;
    while ubound <= rows && input_image(ubound, c) == ON
        ubound = ubound + 1;
    end
    ubound = ubound - 1;
end 

function num = get_point_neighbour(input_image, r, c)
    ON = 0;

    num = 0;
    [rows, columns] = size(input_image);
    if r > 1 && input_image(r - 1, c) == ON
        num = num + 1;
    end
    if r < rows && input_image(r + 1, c) == ON
        num = num + 1;
    end
    if c > 1 && input_image(r, c - 1) == ON
        num = num + 1;
    end
    if c < columns && input_image(r, c + 1) == ON
        num = num + 1;
    end
end

function [output_image, lbound, ubound] = remove_line(input_image, locs, height, order)
    ON = 0;
    OFF = 1;

    output_image = input_image;
    [rows, columns] = size(input_image);
    lbound = zeros(length(locs), columns);      % ????????????????????????????????????????????????????????????0???????????????
    ubound = zeros(length(locs), columns);      % ????????????????????????????????????????????????????????????0???????????????

    if order > 0
        range = 1 : columns;
    else
        range = columns : -1 : 1;
    end

    for i = 1 : length(locs)
        r = locs(i);                            % ????????????????????????
        h = height(i);                          % ???????????????
        lb = 0;                                 % ??????????????????(????????????)
        ub = 0;                                 % ??????????????????(????????????)
        for j = range
            % ???????????????????????????????????????????????????????????????????????????
            if input_image(r, j) == OFF && input_image(r + 1, j) == OFF && input_image(r - 1, j) == OFF
                if lb == 0 || ub == 0
                    continue;
                end
                lbound(i, j) = lb - 1;
                ubound(i, j) = ub + 1;
                output_image(lb : ub, j) = linspace(OFF, OFF, ub - lb + 1);
                continue;
            end
            if input_image(r, j) == ON
                r_temp = r;
            elseif input_image(r + 1, j) == ON
                r_temp = r + 1;
            else
                r_temp = r - 1;
            end
            [lb_temp, ub_temp] = get_line_width(input_image, r_temp, j);    % ?????????????????????????????????????????????
            % if ub_temp - lb_temp + 1 > h + 1
            if ub_temp - lb_temp > h                                % ????????????????????????????????????(+1)
                if lb == 0 || ub == 0
                    continue;
                end                                                 % ??????????????????????????????
            else                                                    % ??????????????????????????????????????????
                lb = lb_temp;
                ub = ub_temp;
            end
            output_image(lb : ub, j) = linspace(OFF, OFF, ub - lb + 1);
            lbound(i, j) = lb - 1;                                  % lbound?????????????????????(?????????)
            ubound(i, j) = ub + 1;                                  % ubound?????????????????????(?????????)
            if lb > 1                                               % ??????????????????????????????
                if output_image(lb - 1, j) == ON && get_point_neighbour(output_image, lb - 1, j) <= 1
                    output_image(lb - 1, j) = OFF;
                    lbound(i, j) = lb - 1;
                end
            end
            if ub < rows
                if output_image(ub + 1, j) == ON && get_point_neighbour(output_image, ub + 1, j) <= 1
                    output_image(ub + 1, j) = OFF;
                    ubound(i, j) = ub + 1;
                end
            end
        end
    end
end

function output_image = restore_line(input_image, lbound, ubound, order)
    ON = 0;
    OFF = 1;

    output_image = input_image;
    [rows, columns] = size(input_image);

    % order>0???????????????????????????????????????????????????
    % order<0???????????????????????????????????????????????????
    if order > 0
        lbound2 = lbound;
        ubound2 = ubound;
    else
        lbound2 = ubound;
        ubound2 = lbound;
    end

    i = 1;
    while i <= columns
        if lbound2(i) > 0 && lbound2(i) <= rows && input_image(lbound2(i), i) == ON % ??????????????????i
            j = i;
            while j <= columns && lbound2(j) > 0 && lbound2(j) <= rows && ...
                input_image(lbound2(j), j) == ON                % ??????????????????j
                j = j + 1;
            end
            j = j - 1;
            lmiddle = floor((i + j) / 2);                       % ????????????lmiddle

            thick = abs(ubound2(lmiddle) - lbound2(lmiddle));
            max_dist = round(thick / tan(pi/9));                % ??????????????????????????????????????????
            umiddle = 0;
            for x = 0 : max_dist + floor((j - i) / 2)           % ???????????????????????????????????????
                if lmiddle + x <= columns && ubound2(lmiddle + x) > 0 && ...
                    ubound2(lmiddle + x) <= rows && ...
                    input_image(ubound2(lmiddle + x), lmiddle + x) == ON
                    umiddle = lmiddle + x;
                    break;
                elseif lmiddle - x >= 1 && ubound2(lmiddle - x) > 0 && ...
                    ubound2(lmiddle - x) <= rows && ...
                    input_image(ubound2(lmiddle - x), lmiddle - x) == ON
                    umiddle = lmiddle - x;
                    break;
                end
            end
            if umiddle == 0                                     % ???????????????????????????
                i = j + 1;
                continue;
            end

            k = umiddle;                                        % ????????????????????????k
            while k >= 1
                if ubound2(k) <= 0 ||  ubound2(k) > rows || input_image(ubound2(k), k) == OFF
                    k = k + 1;
                    break;
                end
                k = k - 1;
            end
            if k < 1
                k = 1;
            end
            l = umiddle;                                        % ????????????????????????l
            while l <= columns
                if ubound2(l) <= 0 || ubound2(l) > rows || input_image(ubound2(l), l) == OFF
                    l = l - 1;
                    break;
                end
                l = l + 1;
            end
            if l > columns
                l = columns;
            end
%             k = umiddle;
%             while k >= 1
%                 if ubound2(k) > 0 && ubound2(k) <= rows && input_image(ubound2(k), k) == OFF
%                     while ubound2(k) <= 0 ||  ubound2(k) > rows || input_image(ubound2(k), k) == OFF
%                         k = k + 1;
%                     end
%                     break;
%                 end
%                 k = k - 1;
%             end
%             if k < 1
%                 k = 1;
%             end
%             l = umiddle;
%             while l <= columns
%                 if ubound2(l) > 0 && ubound2(l) <= rows && input_image(ubound2(l), l) == OFF
%                     while ubound2(l) <= 0 || ubound2(l) > rows || input_image(ubound2(l), l) == OFF
%                         l = l - 1;
%                     end
%                     break;
%                 end
%                 l = l + 1;
%             end
%             if l > columns
%                 l = columns;
%             end
%             if k == 1
%                 k = umiddle;
%             end
%             if l == columns
%                 l = umiddle;
%             end

            % ???????????????????????????
            if order > 0
                l1 = min(lbound2(i), lbound2(j));
                l2 = max(ubound2(k), ubound2(l));
                for m = l1 + 1 : l2 - 1
                    for n = min(i, k) : max(j, l)
                        if atan2(m - l1, n - i) < atan2(l2 - l1, k - i) && ...
                            atan2(m - l1, n - j) > atan2(l2 - l1, l - j)
                            output_image(m, n) = ON;
                            output_image(m + 1, n) = ON;
                        end
                    end
                end
            else
                l1 = max(lbound2(i), lbound2(j));
                l2 = min(ubound2(k), ubound2(l));
                for m = l2 + 1 : l1 - 1
                    for n = min(i, k) : max(j, l)
                        if atan2(m - l1, n - i) > atan2(l2 - l1, k - i) && ...
                            atan2(m - l1, n - j) < atan2(l2 - l1, l - j)
                            output_image(m, n) = ON;
                            output_image(m + 1, n) = ON;
                        end
                    end
                end
            end
            i = j + 1;
        else
            i = i + 1;
        end
    end
end

function output_image = restore_uline(input_image, lbound, ubound)
    ON = 0;
    OFF = 1;

    output_image = input_image;
    [rows, columns] = size(input_image);

    i = 1;
    while i <= columns
        if lbound(i) > 0 && lbound(i) <= rows && input_image(lbound(i), i) == ON % ????????????????????????
            thick = ubound(i) - lbound(i) - 1;              % ???????????????
            max_dist = round(1.4 * thick / tan(pi/9));      % U??????????????????(??????????????????)
            stroke = 0;                                     % ???????????????
            while i <= columns && lbound(i) > 0 && lbound(i) <= rows && ...
                input_image(lbound(i), i) == ON             % ????????????????????????
                i = i + 1;
                stroke = stroke + 1;
            end
            t = min(thick, stroke);                         % ??????????????????????????????????????????????????????
            if i > columns
                break;
            end

            i = i - 1;
            j = i + 1;
            while j <= columns && j <= i + max_dist && ...
                (lbound(j) <= 0 || lbound(j) > rows || input_image(lbound(j), j) == OFF)
                j = j + 1;                                  % ???????????????????????????????????????
            end
            if j > columns                                  % ????????????????????????
                break;
            end
            if j > i + max_dist                             % ?????????????????????????????????????????????
                output_image = complete_line(output_image, lbound, i, t); % ???????????????????????????
                i = j;
                continue;
            end
            if ubound(i) > rows || ubound(j) > rows || ...
                (input_image(ubound(i), i) == ON && input_image(ubound(j), j) == ON)
                i = j;                  % ?????????????????????????????????????????????restore_line???????????????
                continue;
            end
            
            % ???????????????U??????
            r1 = lbound(i);
            r2 = lbound(j);
            r = min(r1, r2);
            c1 = i;
            c2 = j;
            
            isu = false;
            flag = 0;           % ??????U????????????????????????????????????flag>=2???????????????U???
            while r > 0
                if input_image(r, c1) == OFF && input_image(r, c2) == OFF
                    isu = true;
                    break;
                elseif input_image(r, c1) == ON && input_image(r, c2) == OFF
                    c1 = c1 + 1;
                    c2 = c2 + 1;
                    while c2 <= columns && ...
                        input_image(r, c1) == ON && input_image(r, c2) == OFF
                        c1 = c1 + 1;
                        c2 = c2 + 1;
                    end
                    if input_image(r, c1) == OFF
                        isu = true;
                        break;
                    end
                elseif input_image(r, c1) == OFF && input_image(r, c2) == ON
                    c1 = c1 - 1;
                    c2 = c2 - 1;
                    while c1 >= 1 && ...
                        input_image(r, c1) == OFF && input_image(r, c2) == ON
                        c1 = c1 - 1;
                        c2 = c2 - 1;
                    end
                    if input_image(r, c2) == OFF
                        isu = true;
                        break;
                    end
                else
                    if input_image(r, c1 + 1) == ON || input_image(r, c2 - 1) == ON
                        flag = flag + 1;
                        if flag >= 2
                            break;
                        end
                    end
                end
                r = r - 1;
            end
            if ~isu                     % ???????????????????????????
                output_image = complete_line(output_image, lbound, i, t);
                i = j;
                continue;
            end

            % ????????????U??????
            k = i;
            while k >= 1 && lbound(k) > 0 && lbound(k) <= rows && input_image(lbound(k), k) == ON
                k = k - 1;
            end
            k = k + 1;
            l = j;
            while l <= columns && lbound(l) > 0 && lbound(l) <= rows && input_image(lbound(l), l) == ON
                l = l + 1;
            end
            l = l - 1;
            i = i + 1;
            j = j - 1;

            % th = floor(t / 2);
            % middle = round((i + j) / 2);
            l1 = min(lbound(k), lbound(l));
            for m = 1 : t
                for n = k + m : l - m
                    %{
                    if atan2(m - l1, n - k) < atan2(t, middle - k) && ...
                        atan2(m - l1, n - l) > atan2(t, middle - l) && ...
                        (atan2(m - l1, n - i) > atan2(th, middle - i) || ...
                            atan2(m - l1, n - j) < atan2(th, middle - j))
                        output_image(m, n) = 0;
                        output_image(m + 1, n) = 0;
                    end
                    %}
                    output_image(l1 + m, n) = ON;
                end
            end
            i = j + 1;
        else
            i = i + 1;
        end
    end
end

function output_image = complete_line(input_image, lbound, i, t)
    ON = 0;
    OFF = 1;

    output_image = input_image;
    
    k = i;
    while k >= 1 && lbound(k) > 0 && input_image(lbound(k), k) == ON
        k = k - 1;
    end
    k = k + 1;
    l1 = min(lbound(k), lbound(i));
    for m = 1 : t
        for n = k + m : i - m
            output_image(l1 + m, n) = ON;
        end
    end
end
