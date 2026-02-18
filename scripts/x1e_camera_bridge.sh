#!/usr/bin/env bash

set -e

############################################
# How to find your CAMERA_NODE:
#
# 1) List PipeWire video sources:
#    wpctl status
#
# 2) Look under:
#      Video → Sources
#    Find something like:
#      Built-in Front Camera
#
# 3) Get its ID (the number before the dot), e.g.:
#      94. Built-in Front Camera
#
# 4) Inspect it:
#    wpctl inspect 94 | grep node.name
#
# 5) Use the value of node.name below as CAMERA_NODE.
#
# Example output:
#   node.name = "libcamera_input._base_soc_0_cci_ac16000_i2c-bus_1_camera_36"
#
############################################

CAMERA_NODE="libcamera_input._base_soc_0_cci_ac16000_i2c-bus_1_camera_36"
V4L2_DEVICE="/dev/video40"
CARD_LABEL="WebRTC Camera"

echo "[*] Checking v4l2loopback module..."

if ! lsmod | grep -q v4l2loopback; then
  echo "[*] Loading v4l2loopback..."
  sudo modprobe v4l2loopback devices=1 video_nr=40 card_label="$CARD_LABEL" exclusive_caps=1
else
  echo "[*] v4l2loopback already loaded"
fi

if [ ! -e "$V4L2_DEVICE" ]; then
  echo "[!] $V4L2_DEVICE not found"
  exit 1
fi

echo "[*] Starting PipeWire → v4l2 bridge..."
echo "[*] Using camera node: $CAMERA_NODE"
echo "[*] Press Ctrl+C to stop"

trap "echo; echo '[*] Stopping bridge'; exit 0" INT TERM

gst-launch-1.0 -v \
  pipewiresrc target-object=$CAMERA_NODE ! \
  videoconvert ! \
  video/x-raw,format=I420,width=640,height=480,framerate=30/1 ! \
  v4l2sink device=$V4L2_DEVICE sync=false
