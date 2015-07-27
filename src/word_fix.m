function res = word_fix(img)
    [height, width] = size(img);
    img(1:4, :) = 1;
    img((height- 4):end, :) = 1;
    img(:, 1:4) = 1;
    img(:, (width-4):width) = 1;
    res = img;
end