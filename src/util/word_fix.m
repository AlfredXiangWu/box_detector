function res = word_fix(img)
    [height, width] = size(img);
    
    avg = mean(img((height - 1):height, :), 1);
    if numel(find(avg < 0.5)) >0.7*width
        img((height- 1):end, :) = 1;
    end
    
    img(1:4, :) = 1;    
    img(:, 1:4) = 1;
    img(:, (width-4):width) = 1;

    res = img;
end