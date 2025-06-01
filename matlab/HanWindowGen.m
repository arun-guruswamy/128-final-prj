% Parameters
N = 512;                  % FFT frame size
scale_bits = 23;          % Q1.23 fixed-point scaling for 24-bit signed
filename = 'O:\workspace\ENGS128\128-final-prj\matlab\hanning_window_24bit.coe';

% Generate Hanning window (range: 0 to 1)
w = 0.5 * (1 - cos(2*pi*(0:N-1)/(N-1)));

% Scale to fixed-point signed (Q1.23)
scaled_w = round(w * (2^(scale_bits - 1)));  % Max value is 2^22

% Convert to 2's complement if needed (handle negative values)
signed_vals = int32(scaled_w);  % MATLAB uses double by default

% Convert to hex (2's complement, 6 hex digits = 24 bits)
hex_vals = dec2hex(mod(signed_vals, 2^24), 6);  % wrap around with mod

% Write to .coe file
fid = fopen(filename, 'w');
fprintf(fid, 'memory_initialization_radix=16;\n');
fprintf(fid, 'memory_initialization_vector=\n');

for i = 1:N
    if i ~= N
        fprintf(fid, '%s,\n', hex_vals(i, :));
    else
        fprintf(fid, '%s;\n', hex_vals(i, :));  % end with semicolon
    end
end

fclose(fid);
fprintf('COE file written to "%s"\n', filename);
