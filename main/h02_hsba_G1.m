function h02_hsba_G1(fconfig)
%function h02_hsba_G1(fconfig)
% Execute hierarchical splitting for Z- changes
%
% fconfig: user-specified configuration file
%
% NinaLin@2023

loadparam;

eventImg = sprintf('%s/%s.tif',fpmdir,prefix);
qcImg    = sprintf('%s/%s.tif',qcdir,prefix);

thresh = eval(config('threshG1'));
Gtype = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Read the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
ampEventNorm = readRaster(eventImg);
[~,qcprefix] = fileparts(qcImg);
qclog = sprintf('%s/02_hsba.log',qcdir);
tt=toc;

% pad image boundary to the power of two
ampEventNormPad = padarray(ampEventNorm,2.^nextpow2(size(ampEventNorm))-size(ampEventNorm),NaN,'post');

% initialize the split sizes (min dim=32)
if 2.^nextpow2(min(size(ampEventNorm)))<5
    error('Image size is too small. Min side needs to be >32 pixels')
end
dimlist = 2.^[nextpow2(min(size(ampEventNorm)))-1:-1:5]; 
maxdim  = dimlist(1);
mindim  = dimlist(end);

% Initialize tile size based on image dimensions    
logging(qclog,sprintf('Image size: %d, %d',size(ampEventNorm,2),size(ampEventNorm,1)));
logging(qclog,sprintf('Split images in the order of: %d\n',dimlist));
logging(qclog,sprintf('Done loading file %s. %f seconds used.',eventImg,tt));
logging(qclog,sprintf('min splitting dimension: %d',mindim));
logging(qclog,sprintf('max splitting dimension: %d',maxdim));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Hierarchical splitting 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

[seg_map, set_stat] = qtdecomp_prob(ampEventNormPad, thresh, [mindim maxdim], Gtype);
[mAD,mBC,mSR,mAS,mNIA,mG1A,mG1M,mG1S,mG2A,mG2M,mG2S] = block2map(seg_map, set_stat, dimlist, size(ampEventNorm), thresh);
[G1A,G1M,G1S,G2A,G2M,G2S] = selectTile(mBC,mAD,mSR,mAS,mNIA,mG1A,mG1M,mG1S,thresh,Gtype,mG2A,mG2M,mG2S);

save(sprintf('%s/%s_hsba_G1',qcdir,qcprefix),...
     'G1A','G1M','G1S','G2A','G2M','G2S');

ttt = toc;
logging(qclog,sprintf('Total process time is %f seconds',ttt));
 
tlog = sprintf('%s/time_h02',qcdir);
logging(tlog,sprintf('%f',ttt));

return;

