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