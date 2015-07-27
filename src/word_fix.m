function res = word_fix(img)
    [height, width] = size(img);
    img(1:5, :) = 1;
    img((height- 5):end, :) = 1;
    img(:, 1:5) = 1;
    img(:, (width-5):width) = 1;
    res = img;
end