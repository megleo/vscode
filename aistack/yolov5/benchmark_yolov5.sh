#!/bin/bash
#========================================================================

target_arch="aarch64-android"
dsp_arch="hexagon-v68"

long_opts="help,arch:,dsp:"
getopt_cmd=$(getopt -o ha:d: --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "\nERROR: Getopt failed. Extra args\n"; usage; exit 1;}
eval set -- "$getopt_cmd"
snpe_version=$SNPE_VERSION

usage() {
echo -e "\033[1;37mUsage:\033[0m"
echo -e "    bash $0 [OPTIONS]"
echo -e ""
echo -e "\033[1;37mDescription:\033[0m"
echo -e "    Set up Thundercomm AI Stack"
echo -e ""
echo -e "\033[1;37mOPTIONS:\033[0m"
echo -e "    \033[1;37m-h, --help\033[0m       Display this help message"
echo -e "    \033[1;37m-a, --arch\033[0m       SOM target architecture, defacult: 'aarch64-android'"
echo -e "    \033[1;37m-d, --dsp\033[0m        SOM DSP architecture, default: 'hexagon-v68'"
}

echo -e "\033[33m
******************************************************************
Welcome to $0 version $script_version
This script is used to validate yolov5s the SNPE platform based on SNPE $snpe_version.

You can obtain the help information via $0 -h.
******************************************************************
\033[0m
"

while true; do
    case "$1" in
        -h|--help)     usage; exit 0;;
        -a|--arch)     target_arch=$2;;
        -d|--dsp)      dsp_arch=$2;;
        --)            break;;
    esac
    shift

    if [ "$1" = "" ]; then
        break
    fi
done

export SNPE_TARGET_ARCH=$target_arch
export SNPE_TARGET_STL=libc++_shared.so
export SNPE_TARGET_DSPARCH=$dsp_arch

adb shell "mkdir -p /data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/bin"
adb shell "mkdir -p /data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib"
adb shell "mkdir -p /data/local/tmp/snpeexample/dsp/lib"

if [ "$target_arch" == "aarch64-android" ]
    adb push $SNPE_ROOT/lib/$SNPE_TARGET_ARCH/$SNPE_TARGET_STL \
      /data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib
fi
adb push $SNPE_ROOT/lib/$SNPE_TARGET_ARCH/*.so \
      /data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib
adb push $SNPE_ROOT/lib/$SNPE_TARGET_DSPARCH/unsigned/*.so \
      /data/local/tmp/snpeexample/dsp/lib
adb push $SNPE_ROOT/bin/$SNPE_TARGET_ARCH/snpe-net-run \
      /data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/bin

cd $SNPE_ROOT/examples/Models/yolov5
mkdir data/rawfiles && cp data/cropped/*.raw data/rawfiles/
adb shell "mkdir -p /data/local/tmp/yolov5"
adb push data/rawfiles /data/local/tmp/yolov5/cropped
adb push data/target_raw_list.txt /data/local/tmp/yolov5
adb push dlc/*dlc /data/local/tmp/yolov5
rm -rf data/rawfiles

echo -e ""
echo -e "***********************Test CPU***************************************************"
adb shell "export SNPE_TARGET_ARCH=aarch64-android && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib && export PATH=$PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/bin && cd /data/local/tmp/yolov5 && snpe-net-run --container yolov5_quantized.dlc --input_list target_raw_list.txt"
adb pull /data/local/tmp/yolov5/output output_android_cpu
adb shell "rm -rf /data/local/tmp/yolov5/output"
python3 $SNPE_ROOT/examples/Models/yolov5/scripts/show_inceptionv3_classifications.py -i $SNPE_ROOT/examples/Models/yolov5/data/target_raw_list.txt \
                                                   -o $SNPE_ROOT/examples/Models/yolov5/output_android_cpu/ \
                                                   -l $SNPE_ROOT/examples/Models/yolov5/data/imagenet_slim_labels.txt

echo -e ""
echo -e "***********************Test GPU***************************************************"
adb shell "export SNPE_TARGET_ARCH=aarch64-android && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib && export PATH=$PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/bin && cd /data/local/tmp/yolov5 && snpe-net-run --container yolov5_quantized.dlc --input_list target_raw_list.txt --use_gpu"
adb pull /data/local/tmp/yolov5/output output_android_gpu
adb shell "rm -rf /data/local/tmp/yolov5/output"
python3 $SNPE_ROOT/examples/Models/yolov5/scripts/show_inceptionv3_classifications.py -i $SNPE_ROOT/examples/Models/yolov5/data/target_raw_list.txt \
                                                   -o $SNPE_ROOT/examples/Models/yolov5/output_android_gpu/ \
                                                   -l $SNPE_ROOT/examples/Models/yolov5/data/imagenet_slim_labels.txt


echo -e ""
echo -e "***********************Test DSP***************************************************"
adb shell "export SNPE_TARGET_ARCH=aarch64-android && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/lib && export PATH=$PATH:/data/local/tmp/snpeexample/$SNPE_TARGET_ARCH/bin && export ADSP_LIBRARY_PATH=\"/data/local/tmp/snpeexample/dsp/lib;/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp\" && cd /data/local/tmp/yolov5 && snpe-net-run --container yolov5_quantized_cache.dlc --input_list target_raw_list.txt --use_dsp"
adb pull /data/local/tmp/yolov5/output output_android_dsp
adb shell "rm -rf /data/local/tmp/yolov5/output"
python3 $SNPE_ROOT/examples/Models/yolov5/scripts/show_inceptionv3_classifications.py -i $SNPE_ROOT/examples/Models/yolov5/data/target_raw_list.txt \
                                                   -o $SNPE_ROOT/examples/Models/yolov5/output_android_dsp/ \
                                                   -l $SNPE_ROOT/examples/Models/yolov5/data/imagenet_slim_labels.txt

echo -e ""
echo -e "********************** Delete Files *********************************************"
rm -rf output_android_cpu output_android_gpu output_android_dsp
adb shell "rm -rf /data/local/tmp/*"
