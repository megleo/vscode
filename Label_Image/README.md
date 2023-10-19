# TFLite Inference Tool Using Tutorial

​		This Project is for SOM Platform to verify Tensorflow Lite availability. Because there is no label_image executable tool in SOM android operating system, we should compile the tool ourselves .



[TOC]

## 1. Setup Environment

- Network

​		Since the company's wired network cannot access foreign resources, we recommend using the company's wireless network.

- Docker

  Tensorflow provides docker, in order to reduce local environment factors, it is recommend to use docker .

  - Install Docker

    ```shell
    sudo apt-get update
    ```

    ```shell
    sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    ```

    ```shell
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    ```

    ```shell
    sudo apt-key fingerprint 0EBFCD88
    
    
    ```

    ```shell
     sudo apt-get update
    ```

    ```shell
    sudo apt-get install docker-ce
    ```

    ```shell
    sudo docker run hello-world
    
    > Hello from Docker!
    > This message shows that your installation appears to be working correctly.
    
    > To generate this message, Docker took the following steps:
    >  1. The Docker client contacted the Docker daemon.
    >  2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    >    (amd64)
    >  3. The Docker daemon created a new container from that image which runs the
    >     executable that produces the output you are currently reading.
    >  4. The Docker daemon streamed that output to the Docker client, which sent it
    >     to your terminal.
    
    > To try something more ambitious, you can run an Ubuntu container with:
    >  $ docker run -it ubuntu bash
    
    > Share images, automate workflows, and more with a free Docker ID:
    >  https://hub.docker.com/
    
    > For more examples and ideas, visit:
    >  https://docs.docker.com/get-started/
    
    ```
    
    

- Tensorflow Source Code

  ```shell
  git clone https://github.com/tensorflow/tensorflow.git
  ```

## 2. Compile

### 2.1 Docker Environment

1. ```shell
   # enter into tensorlow folder
   cd tensorflow 
   # enter to docker
   docker pull tensorflow/tensorflow:devel
   docker run -it -w /tensorflow_src -v $PWD:/mnt -e HOST_PERMS="$(id -u):$(id -g)" tensorflow/tensorflow:devel bash
   git pull
   ```

2. Install Android SDK and NDK environment

   - Download the android-ndk-r21e-linux-x86_64.zip and adroid-sdk_r24.2-linux.tgz .

   - Using  HFS software to make a simple HTTP site and upload our SDK and NDK resources.

   - Using wget to get the the NDK and SDK resources in docker. (Can also using Docker command to upload the resources)

   - unzip the resources to /opt/

   - Add the environment path.

   ```shell
   vim ~/.bashrc
   # add the follow to .bashrc
   
   export ANDROID_PATH=/opt/android-sdk-linux
   export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platforms
   
   export NDK_ROOT=/opt/android-ndk-r21e
   export PATH=$PATH:$NDK_ROOT
   ```

### 2.2 Compile 

1.  Configure the compilation environment

   ```shell
   python configure.py
   -----------------------------------------------------------------------------------------------------------------------------
   You have bazel 5.1.1 installed.
   Please specify the location of python. [Default is /home/ts/anaconda3/bin/python]: 
   
   
   Found possible Python library paths:
     /home/ts/anaconda3/lib/python3.8/site-packages
   Please input the desired Python library path to use.  Default is [/home/ts/anaconda3/lib/python3.8/site-packages]
   
   Do you wish to build TensorFlow with ROCm support? [y/N]: N
   No ROCm support will be enabled for TensorFlow.
   
   Do you wish to build TensorFlow with CUDA support? [y/N]: N
   No CUDA support will be enabled for TensorFlow.
   
   Do you wish to download a fresh release of clang? (Experimental) [y/N]: N
   Clang will not be downloaded.
   
   Please specify optimization flags to use during compilation when bazel option "--config=opt" is specified [Default is -Wno-sign-compare]: -Wno-sign-compare
   
   
   Would you like to interactively configure ./WORKSPACE for Android builds? [y/N]: y
   Searching for NDK and SDK installations.
   
   Please specify the home path of the Android NDK to use. [Default is /home/ts/Android/Sdk/ndk-bundle]: SDK PATH
   
   ```

2. Compile using the following command 

   Build it for desktop machines (tested on Ubuntu and OS X):

   ```shell
   bazel build -c opt //tensorflow/lite/examples/label_image:label_image
   ```

   Build it for Android ARMv8:

   ```shell
   bazel build -c opt --config=android_arm64 \
     //tensorflow/lite/examples/label_image:label_image
   ```

   Build it for Android arm-v7a:

   ```shell
   bazel build -c opt --config=android_arm \
     //tensorflow/lite/examples/label_image:label_image
   ```

### 2.3 FAQ

1. It does no contain the subdirectories "platforms" and "build-tools"

   ```
   vim configure.py
   
   # change the build-tools to tools
    665   def valid_sdk_path(path):
    666     return (os.path.exists(path) and
    667             os.path.exists(os.path.join(path, 'platforms')) and
    668             os.path.exists(os.path.join(path, 'build-tools')))
    669 
    670   android_sdk_home_path = prompt_loop_or_load_from_env(
    671       environ_cp,
    672       var_name='ANDROID_SDK_HOME',
    673       var_default=default_sdk_path,
    674       ask_for_var='Please specify the home path of the Android SDK to use.',
    675       check_success=valid_sdk_path,
    676       error_msg=('Either %s does not exist, or it does not contain the '
    677                  'subdirectories "platforms" and "build-tools".'))
   
   
   ```

2. Error；

   ```shell
   ERROR: An error occurred during the fetch of repository 'tf_runtime':
      Traceback (most recent call last):
   	File "/home/ts/NNAPITest/tensorflow/third_party/repo.bzl", line 73, column 33, in _tf_http_archive_impl
   		ctx.download_and_extract(
   Error in download_and_extract: java.io.IOException: Error downloading [https://storage.googleapis.com/mirror.tensorflow.org/github.com/tensorflow/runtime/archive/fb86560c19d2e8956e1581d69ba6757c7fdcac2c.tar.gz, https://github.com/tensorflow/runtime/archive/fb86560c19d2e8956e1581d69ba6757c7fdcac2c.tar.gz] to /home/ts/.cache/bazel/_bazel_ts/60019a753095595a8d6739a38f7fcee3/external/tf_runtime/temp9257820580758056332/fb86560c19d2e8956e1581d69ba6757c7fdcac2c.tar.gz: connect timed out
   ```

   This is due to Network. You can download the package and make a yourself http  and then add your http to bzl file just like this .

   ```
   
   vi tensorflow/workspace.bzl
   # 找到llvm
    LLVM_COMMIT = "c4b5a66e44f031eb89c9d6ea32b144f1169bdbae"
       LLVM_SHA256 = "8463cbed08a66c7171c831e9549076cf3fd4f7e6fe690b9b799d6afef2465007"
       LLVM_URLS = [
           "https://storage.googleapis.com/mirror.tensorflow.org/github.com/llvm/llvm-project/archive/{commit}.tar.gz".format(commit = LLVM_COMMIT),
       "http://127.0.0.1:1234/{commit}.tar.gz".format(commit = LLVM_COMMIT),#添加这行
           "https://github.com/llvm/llvm-project/archive/{commit}.tar.gz".format(commit = LLVM_COMMIT),
   
   ```

## 3. Test

   ### 3.1 Download sample model and image

   You can use any compatible model, but the following MobileNet v1 model offers a good demonstration of a model trained to recognize 1,000 different objects.

   ```shell
   # Get model
   curl https://storage.googleapis.com/download.tensorflow.org/models/mobilenet_v1_2018_02_22/mobilenet_v1_1.0_224.tgz | tar xzv -C /tmp
   
   # Get labels
   curl https://storage.googleapis.com/download.tensorflow.org/models/mobilenet_v1_1.0_224_frozen.tgz  | tar xzv -C /tmp  mobilenet_v1_1.0_224/labels.txt
   
   mv /tmp/mobilenet_v1_1.0_224/labels.txt /tmp/
   ```

   ### 3.2 Run

   - Android

   ```shell
   adb wait-for-device
   adb root
   adb remount
   adb shell "mkdir -p /data/tf"
   
   adb push ./label_image/mobilenet_quant_v1_224.tflite /data/tf
   adb push ./label_image/labels.txt /data/tf
   adb push ./label_image/grace_hopper.bmp /data/tf
   adb push ./label_image/label_image /data/tf
   
   adb shell "chmod 777 data/tf/label_image && cd data/tf/ && ./label_image -a 1 -m mobilenet_quant_v1_224.tflite -c 10 "
   
   ```

   - LE and LU

   ```shell
   
   ```

   - Results
   
     ```shell
     ./label_image/mobilenet_quant_v1_224.tflite: 1 file pushed. 29.6 MB/s (4276100 bytes in 0.138s)
     ./label_image/labels.txt: 1 file pushed. 2.4 MB/s (10484 bytes in 0.004s)
     ./label_image/grace_hopper.bmp: 1 file pushed. 31.2 MB/s (940650 bytes in 0.029s)
     ./label_image/label_image: 1 file pushed. 29.1 MB/s (6748176 bytes in 0.221s)
     INFO: Loaded model mobilenet_quant_v1_224.tflite
     INFO: resolved reporter
     INFO: Initialized TensorFlow Lite runtime.
     INFO: Created TensorFlow Lite delegate for NNAPI.
     NNAPI delegate created.
     INFO: Applied NNAPI delegate.
     INFO: invoked
     INFO: average time: 7.0921 ms
     INFO: 0.666667: 458 bow tie
     INFO: 0.290196: 653 military uniform
     INFO: 0.0117647: 835 suit
     INFO: 0.00784314: 611 jersey
     INFO: 0.00392157: 922 book jacket
     ```

## 4. SOM Platform Results

|      |  LA  |  LE  |  LU  |
| :--: | :--: | :--: | :--: |
| 410  | pass |  -   |  -   |
| RB5  | pass | pass | pass |
| 610  | pass | pass |  -   |

\- : 系统版本不存在或者没找到该系统版本。
