%
% Basic JPL shift function from the L1C ATBD
%
function Tb_resamp = jpl_shift(Tb_in, v_in, v_nom);

currentFilePath = mfilename('fullpath');
[cfpath, cfname, cfext] = fileparts(currentFilePath);

persistent a b
if isempty(a) | isempty(b)
   load(fullfile(cfpath, '../static/umbc_shift_1c.mat'), 'a', 'b');
end

Tb_in = Tb_in(:);
v_in = v_in(:);
v_nom = v_nom(:);

dv = v_nom - v_in;

Tb_spline = interp1(v_in, Tb_in, v_nom, 'spline');
Tb_resamp = Tb_in + (a .* (Tb_spline - Tb_in) ./ dv + b) .* dv;
