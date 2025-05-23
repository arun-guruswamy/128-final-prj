% generate_fft_colormap_coe.m
% Creates a .coe file with 256 24-bit RGB values (one per FFT bin)

filename = 'fft_colormap.coe';
fid = fopen(filename, 'w');

fprintf(fid, 'memory_initialization_radix=16;\n');
fprintf(fid, 'memory_initialization_vector=\n');

N = 256;  % Number of bins
for i = 0:N-1
    % Calculate RGB as a smooth gradient (blue -> green -> red)
    if i <= 128
        % Blue to Green
        r = 0;
        g = round(255 * i / 128);
        b = round(255 * (128 - i) / 128);
    else
        % Green to Red
        r = round(255 * (i - 128) / 127);
        g = round(255 * (255 - i) / 127);
        b = 0;
    end

    % Clamp to 0–255
    r = max(0, min(r, 255));
    g = max(0, min(g, 255));
    b = max(0, min(b, 255));

    % Pack into 24-bit RGB: 0xRRGGBB
    rgb_hex = sprintf('%02X%02X%02X', r, g, b);

    % Write to file with comma or semicolon
    if i < N-1
        fprintf(fid, '%s,\n', rgb_hex);
    else
        fprintf(fid, '%s;\n', rgb_hex);  % Final entry ends with semicolon
    end
end

fclose(fid);
fprintf('COE file "%s" generated successfully.\n', filename);
