% function test_bug1775

% TEST test_bug1775
% TEST ft_sourceparcellate ft_datatype_source ft_datatype_parcellation ft_datatype_segmentation



%% create a set of sensors

[pnt, tri] = icosahedron162;

pnt = pnt .* 10; % convert to cm
sel = find(pnt(:,3)>0);

grad.pnt = pnt(sel,:) .* 1.2;
grad.ori = pnt(sel,:);
grad.tra = eye(length(sel));
for i=1:length(sel)
  grad.ori(i,:) = grad.ori(i,:) ./ norm(grad.ori(i,:));
  grad.label{i} = sprintf('magnetometer%d', i);
end
grad.unit = 'cm';
grad.type = 'magnetometer';

grad = ft_datatype_sens(grad);


%% create a volume conductor

vol = [];
vol.r = 10;
vol.o = [0 0 0];
vol.unit = 'cm';

vol = ft_datatype_headmodel(vol);

%% create some precomputed leadfields

cfg = [];
cfg.grad = grad;
cfg.vol = vol;
cfg.grid.resolution = 1;
cfg.channel = 'all';
grid = ft_prepare_leadfield(cfg);

%% create an anatomical parcellation
parcellation = [];
parcellation.pos = grid.pos;
parcellation.unit = grid.unit;
parcellation.type      = zeros(size(grid.pos,1),1);
parcellation.typelabel = {};
height = [3 4 5 6 7 8 9];
for i=1:length(height)
  sel = parcellation.pos(:,3)==height(i);
  parcellation.type(sel) = i;
  parcellation.typelabel{i} = sprintf('%d%s', height(i), parcellation.unit);
end
parcellation.cfg = 'manual'; % to check whether the provenance is correct

%% create simulated data
cfg = [];
cfg.grad = grad;
cfg.vol = vol;
cfg.dip.pos = [0 0 4];
data = ft_dipolesimulation(cfg);

cfg = [];
cfg.covariance = 'yes';
timelock = ft_timelockanalysis(cfg, data);

cfg = [];
cfg.method = 'mtmfft';
cfg.taper = 'hanning';
freq1 = ft_freqanalysis(cfg, data);

cfg = [];
cfg.method = 'wavelet';
cfg.toi = data.time{1};
freq2 = ft_freqanalysis(cfg, data);

cfg = [];
cfg.grad = grad;
cfg.vol = vol;
cfg.grid = grid;
cfg.method = 'lcmv';
source1 = ft_sourceanalysis(cfg, timelock);

cfg = [];
cfg.grad = grad;
cfg.vol = vol;
cfg.grid = grid;
cfg.method = 'mne';
cfg.lambda = 0;
source2 = ft_sourceanalysis(cfg, timelock);


%% make some parcellations
cfg = [];
gridp    = ft_sourceparcellate(cfg, grid, parcellation);
source1p = ft_sourceparcellate(cfg, source1, parcellation);
source2p = ft_sourceparcellate(cfg, source2, parcellation);


