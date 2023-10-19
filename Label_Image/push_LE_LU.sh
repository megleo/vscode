adb wait-for-device
adb root
adb remount
adb shell "mkdir -p /data/tf"

adb push ./label_image/mobilenet_quant_v1_224.tflite /data/tf
adb push ./label_image/labels.txt /data/tf
adb push ./label_image/grace_hopper.bmp /data/tf


adb shell "cd /data/tf/ && label_image -a 1 -m mobilenet_quant_v1_224.tflite -c 10 "
