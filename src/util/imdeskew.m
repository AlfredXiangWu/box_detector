function [ dst, theta ] = imdeskew( src, max_angle, resolution, plotOn ) 
% FUNCTION: imdeskew is used to deskew an input binary image
% -------------------------------------------------------------------------
% Input: 
%       src = an input document image, ideally a binary image, but can be
%             grayscale or color
% max_angle = max allowed angle to deskew   ( default 15 )
% resolution= angle resolution in searching ( default .5 )
%    plotON = optional result display
%
% Output:
%       dst = optimal deskew image
%     theta = optimal deskew angle in degrees
% -------------------------------------------------------------------------
% Sample Code:
%     src = imread( '300.tif' );
%     [ dst, theta ] = imdeskew( src );
% -------------------------------------------------------------------------
% Image Credits:
%     All test images are from 2013 ICDAR handwriting segmentation contest
% http://users.iit.demokritos.gr/~nstam/ICDAR2013HandSegmCont/resources.html
% -------------------------------------------------------------------------
% Author Info:
%     Dr. Yue Wu, ywu03@ece.tufts.edu
% -------------------------------------------------------------------------

% 0. parameter settings
if nargin <= 1
    max_angle   = 15;
    resolution  = .5;
    plotOn      = 0;
elseif nargin <= 2
    resolution  = .5;
    plotOn      = 0;
elseif nargin <= 3
    plotOn      = 0;
else
    error('unsupported input format')
end
% input settings
if size( src, 3 ) > 1 
    display('warning: automatic converting color image to binary')
    gray = rgb2gray( src );
    src  = gray > graythresh( gray ) * 255;
else
    if ~islogical( src )
        display('warning: automatic converting grayscale image to binary')
        src = src > graythresh( src ) * 255;
    end
end
% 1. extract black text pixels for analysis
[ h, w ]    = size( src );
[ text_x, text_y ] = ind2sub(  [ h,w ], find( src(:) == 0 ) );
% 2. compute the information entroy of a projection profile
angles = -max_angle : resolution : max_angle;
cx  = h/2;
cy  = w/2;
len = size( text_x, 1 );
hist_to_prob = @( h ) ( h( h ~= 0 ) / len );
score = [];
for a = angles
    sin_a = sin( a / 180 * pi );
    cos_a = cos( a / 180 * pi );
    sx    = round( ( text_x - cx ) * cos_a + ( text_y -cy ) * sin_a + cx );
    freq  = hist( sx, unique(sx) );
    prob  = hist_to_prob( freq );
    entropy = -prob .* log( prob );
    score(end+1) = sum( entropy(:) );
end
% 3. generate output
[ val, min_idx ] = min( score );
theta = -angles( min_idx );
dst = not( imrotate( not( src ), theta, 'loose' ) );

if plotOn
    figure(10),subplot(131),plot( -angles, score ), xlabel( 'deskew angle: degree' ), ylabel( 'projection profile entropy ' );
    hold on, line( [ -angles( min_idx ), -angles( min_idx )]' , [ min( score )-.1, max( score ) ]', 'color',[1,0,0] )
    hold on, text(  -angles( min_idx )-1, max( score )-.2 , 'optimal deskew angle' ),axis square
    subplot(132),imshow( imerode(src, ones(3) ) ); title( 'before deskew ');
    subplot(133),imshow( imerode(dst, ones(3) ) ); title( 'after deskew' );
end
% 4. discussions
% a). Code in Sec 2 is equivalent to doing hough transform, but my 
%     alternative is more efficient.
% b). It is also possible to find optimal angle in a smarter way, e.g. 
%     gradient descent;
% c). One may use other criterion instead of information entropy, but 
%     the entropy metric is already a good one, because it simply means
%     that we are looking for an angle making src image most determined.