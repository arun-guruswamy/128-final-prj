# 128-final-prj

Hardware Design:
New Sources (found in hw/sources_1/new):

* audio_passthrough.vhd: Primary wrapper responsible for audio generation from DDS or I2S
passthrough.

* video_gen.vhd: Responsible for generating the pixels that will be transformed by video_transform
before being displayed on the screen. Uses the video timing controller for timing and the dynamic
clock generator for the pixel clock.

* axi_fifo.vhd: A custom fifo compliant with axis protocol, that buffers 512 samples for the FFT,
and handles multiplying coefficients as part of our Hanning Window implementation.
video_transform.vhd: A wrapper for rgb_transform and fft_axi_rx and FFT IP core that helps
connect each of them

* fft_axi_rx.vhd: A modified version of the standard AXI receiver from previous labs. It receives
frequency data from the FFT IP Core and identifies the peak frequency bin which it outputs to
rgb_transform.

* rgb_transform.vhd: Receives video data from video_gen and frequency data from fft_axi_rx.
Uses both of these inputs to make sure it changes the color of the pixels for moving blocks only.
Old Sources (found in hw/sources_1/imports): Existing sources imported from previous labs.


Hardware Simulation (found in hw/sim_1/new): Relevant testbenches created.

* tb_vivado_fft.vhd

* tb_video_transform.vhd

* tb_video_transform.vhd

* tb_video_gen.vhd

* tb_rgb_transform.vhd

* tb_general.txt

* tb_fft_axi_rx.vhd

* tb_axis_fifo.vhd

IP Cores (found in hw/sources_1/ip): A folder containing .xci files of Vivado IP core blocks.

Software (found in sdk/): Integration of the lab 3 AXI LITE DDS serial control and the given HDMI
simple demo display sdk package.

Matlab (found in matlab/): Coefficient and coefficient generating files for 3 memory blocks for dds, rgb
colormap, and the han window
