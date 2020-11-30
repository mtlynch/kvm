#!/usr/bin/env bash

# This script is copied from the TinyPilot project, which is released under the MIT license:

# Copyright 2020 Michael Lynch
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Configures USB gadgets per: https://www.kernel.org/doc/Documentation/usb/gadget_configfs.txt

# Exit on first error.
set -e

# Echo commands to stdout.
set -x

# Treat undefined environment variables as errors.
set -u

modprobe libcomposite

# Adapted from https://github.com/girst/hardpass-sendHID/blob/master/README.md

cd /sys/kernel/config/usb_gadget/
mkdir -p g1
cd g1

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB    # USB2

STRINGS_DIR="strings/0x409"
mkdir -p "$STRINGS_DIR"
echo "6b65796d696d6570690" > "${STRINGS_DIR}/serialnumber"
echo "tinypilot" > "${STRINGS_DIR}/manufacturer"
echo "Multifunction USB Device" > "${STRINGS_DIR}/product"

# Keyboard
KEYBOARD_FUNCTIONS_DIR="functions/hid.keyboard"
mkdir -p "$KEYBOARD_FUNCTIONS_DIR"
echo 1 > "${KEYBOARD_FUNCTIONS_DIR}/protocol" # Keyboard
echo 1 > "${KEYBOARD_FUNCTIONS_DIR}/subclass" # Boot interface subclass
echo 8 > "${KEYBOARD_FUNCTIONS_DIR}/report_length"
# Write the report descriptor
# Source: https://www.kernel.org/doc/html/latest/usb/gadget_hid.html
D=$(mktemp)
echo -ne \\x05\\x01 >> "$D" # USAGE_PAGE (Generic Desktop)
echo -ne \\x09\\x06 >> "$D" # USAGE (Keyboard)
echo -ne \\xa1\\x01 >> "$D" # COLLECTION (Application)
echo -ne \\x05\\x07 >> "$D" #   USAGE_PAGE (Keyboard)
echo -ne \\x19\\xe0 >> "$D" #   USAGE_MINIMUM (Keyboard LeftControl)
echo -ne \\x29\\xe7 >> "$D" #   USAGE_MAXIMUM (Keyboard Right GUI)
echo -ne \\x15\\x00 >> "$D" #   LOGICAL_MINIMUM (0)
echo -ne \\x25\\x01 >> "$D" #   LOGICAL_MAXIMUM (1)
echo -ne \\x75\\x01 >> "$D" #   REPORT_SIZE (1)
echo -ne \\x95\\x08 >> "$D" #   REPORT_COUNT (8)
echo -ne \\x81\\x02 >> "$D" #   INPUT (Data,Var,Abs)
echo -ne \\x95\\x01 >> "$D" #   REPORT_COUNT (1)
echo -ne \\x75\\x08 >> "$D" #   REPORT_SIZE (8)
echo -ne \\x81\\x03 >> "$D" #   INPUT (Cnst,Var,Abs)
echo -ne \\x95\\x05 >> "$D" #   REPORT_COUNT (5)
echo -ne \\x75\\x01 >> "$D" #   REPORT_SIZE (1)
echo -ne \\x05\\x08 >> "$D" #   USAGE_PAGE (LEDs)
echo -ne \\x19\\x01 >> "$D" #   USAGE_MINIMUM (Num Lock)
echo -ne \\x29\\x05 >> "$D" #   USAGE_MAXIMUM (Kana)
echo -ne \\x91\\x02 >> "$D" #   OUTPUT (Data,Var,Abs)
echo -ne \\x95\\x01 >> "$D" #   REPORT_COUNT (1)
echo -ne \\x75\\x03 >> "$D" #   REPORT_SIZE (3)
echo -ne \\x91\\x03 >> "$D" #   OUTPUT (Cnst,Var,Abs)
echo -ne \\x95\\x06 >> "$D" #   REPORT_COUNT (6)
echo -ne \\x75\\x08 >> "$D" #   REPORT_SIZE (8)
echo -ne \\x15\\x00 >> "$D" #   LOGICAL_MINIMUM (0)
echo -ne \\x25\\x65 >> "$D" #   LOGICAL_MAXIMUM (101)
echo -ne \\x05\\x07 >> "$D" #   USAGE_PAGE (Keyboard)
echo -ne \\x19\\x00 >> "$D" #   USAGE_MINIMUM (Reserved)
echo -ne \\x29\\x65 >> "$D" #   USAGE_MAXIMUM (Keyboard Application)
echo -ne \\x81\\x00 >> "$D" #   INPUT (Data,Ary,Abs)
echo -ne \\xc0 >> "$D"      # END_COLLECTION
cp "$D" "${KEYBOARD_FUNCTIONS_DIR}/report_desc"

# Mouse
MOUSE_FUNCTIONS_DIR="functions/hid.mouse"
mkdir -p "$MOUSE_FUNCTIONS_DIR"
echo 0 > "${MOUSE_FUNCTIONS_DIR}/protocol"
echo 0 > "${MOUSE_FUNCTIONS_DIR}/subclass"
echo 5 > "${MOUSE_FUNCTIONS_DIR}/report_length"
# Write the report descriptor
D=$(mktemp)
echo -ne \\x05\\x01 >> "$D"      # USAGE_PAGE (Generic Desktop)
echo -ne \\x09\\x02 >> "$D"      # USAGE (Mouse)
echo -ne \\xA1\\x01 >> "$D"      # COLLECTION (Application)
                                 #   8-buttons
echo -ne \\x05\\x09 >> "$D"      #   USAGE_PAGE (Button)
echo -ne \\x19\\x01 >> "$D"      #   USAGE_MINIMUM (Button 1)
echo -ne \\x29\\x08 >> "$D"      #   USAGE_MAXIMUM (Button 8)
echo -ne \\x15\\x00 >> "$D"      #   LOGICAL_MINIMUM (0)
echo -ne \\x25\\x01 >> "$D"      #   LOGICAL_MAXIMUM (1)
echo -ne \\x95\\x08 >> "$D"      #   REPORT_COUNT (8)
echo -ne \\x75\\x01 >> "$D"      #   REPORT_SIZE (1)
echo -ne \\x81\\x02 >> "$D"      #   INPUT (Data,Var,Abs)
                                 #   x,y absolute coordinates
echo -ne \\x05\\x01 >> "$D"      #   USAGE_PAGE (Generic Desktop)
echo -ne \\x09\\x30 >> "$D"      #   USAGE (X)
echo -ne \\x09\\x31 >> "$D"      #   USAGE (Y)
echo -ne \\x16\\x00\\x00 >> "$D" #   LOGICAL_MINIMUM (0)
echo -ne \\x26\\xFF\\x7F >> "$D" #   LOGICAL_MAXIMUM (32767)
echo -ne \\x75\\x10 >> "$D"      #   REPORT_SIZE (16)
echo -ne \\x95\\x02 >> "$D"      #   REPORT_COUNT (2)
echo -ne \\x81\\x02 >> "$D"      #   INPUT (Data,Var,Abs)
                                 #   vertical wheel
echo -ne \\x09\\x38 >> "$D"      #   USAGE (wheel)
echo -ne \\x15\\x81 >> "$D"      #   LOGICAL_MINIMUM (-127)
echo -ne \\x25\\x7F >> "$D"      #   LOGICAL_MAXIMUM (127)
echo -ne \\x75\\x08 >> "$D"      #   REPORT_SIZE (8)
echo -ne \\x95\\x01 >> "$D"      #   REPORT_COUNT (1)
echo -ne \\x81\\x06 >> "$D"      #   INPUT (Data,Var,Rel)
                                 #   horizontal wheel
echo -ne \\x05\\x0C >> "$D"      #   USAGE_PAGE (Consumer Devices)
echo -ne \\x0A\\x38\\x02 >> "$D" #   USAGE (AC Pan)
echo -ne \\x15\\x81 >> "$D"      #   LOGICAL_MINIMUM (-127)
echo -ne \\x25\\x7F >> "$D"      #   LOGICAL_MAXIMUM (127)
echo -ne \\x75\\x08 >> "$D"      #   REPORT_SIZE (8)
echo -ne \\x95\\x01 >> "$D"      #   REPORT_COUNT (1)
echo -ne \\x81\\x06 >> "$D"      #   INPUT (Data,Var,Rel)
echo -ne \\xC0 >> "$D"           # END_COLLECTION
cp "$D" "${MOUSE_FUNCTIONS_DIR}/report_desc"

CONFIG_INDEX=1
CONFIGS_DIR="configs/c.${CONFIG_INDEX}"
mkdir -p "$CONFIGS_DIR"
echo 250 > "${CONFIGS_DIR}/MaxPower"

CONFIGS_STRINGS_DIR="${CONFIGS_DIR}/strings/0x409"
mkdir -p "$CONFIGS_STRINGS_DIR"
echo "Config ${CONFIG_INDEX}: ECM network" > "${CONFIGS_STRINGS_DIR}/configuration"

ln -s "$KEYBOARD_FUNCTIONS_DIR" "${CONFIGS_DIR}/"
ln -s "$MOUSE_FUNCTIONS_DIR" "${CONFIGS_DIR}/"
ls /sys/class/udc > UDC

chmod 777 /dev/hidg0
chmod 777 /dev/hidg1
