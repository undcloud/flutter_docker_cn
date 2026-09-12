# flutter_docker_cn
Running a Flutter demo in a Docker container
解决中国网络问题

# flutter 

## docker 配置环境  

### 前置条件  
以下配置是在ubuntu系统电脑上完成的

### 配置容器  

cd /h/flutter/docker    
docker build -t flutter_android:v1.0 .  
docker run -it -p 8080:8080 -w /app -e DISPLAY=$DISPLAY -e UID=$(id -u) -e GID=$(id -g)   --device=/dev/bus --device /dev/kvm --device /dev/dri -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/bus/usb:/dev/bus/usb --shm-size=2g  flutter_android:v1.0  /bin/bash  
flutter doctor  

### 运行web demo
使用vscode flutter插件，创建一个flutter项目，进入到项目根目录，运行：  
cd /app/   
flutter create counter_demo  
cd counter_demo  
flutter run -d web-server --web-port=8080  


### 开启模拟器  
需要在宿主机允许docker使用图形界面：  
xhost +local:docker  

配置好容器后    
启动模拟器：  
flutter emulators --launch flutter_emulator  

可以运行android demo   

### 使用模拟器运行android demo  
Check for Android devices  
flutter emulators && flutter devices  
cd /app/   
flutter create counter_demo  

修改\app\counter_demo\android\gradle\wrapper\gradle-wrapper.properties  
```
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.14-all.zip
```

修改\app\counter_demo\android\build.gradle.kts
```
allprojects {
    repositories {
        maven {
            url = uri("https://maven.aliyun.com/repository/google")
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/public")
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/gradle-plugin")
        }

        google()
        mavenCentral()
    }
}

```

cd /app/counter_demo  
flutter emulators && flutter devices  
记下模拟器或运行设备id:  

flutter run -d emulator-5554 -v  

调试：  
    安装vscode dart插件  
    启动模拟器后，点击/app/counter_demo/lib/main.dart文件，点击设置断点，再点击debug按钮就可以在模拟器中调试了  


### USB运行demo
在宿主机关闭adb[可选]  
adb kill-server  


手机开启调试模式，勾选 ✅ "始终允许使用此计算机进行调试"  
flutter devices  

flutter run -d ZY22G3TJJ7 -v  

### 参考资料
https://hub.docker.com/layers/cirrusci/flutter/3.8.0-10.1.pre/images/sha256-56e92d9337bf889834163c3531feb5ff268cc98eb55300e317704e10de8090fc  
    android  


https://hub.docker.com/r/instrumentisto/flutter  
    Android  
    Linux  
    Web  
https://hub.docker.com/r/matspfeiffer/flutter  
https://github.com/matsp/docker-flutter/blob/master/stable/Dockerfile  
https://hub.docker.com/layers/plugfox/flutter/3.44.8-android/images/sha256-264bf1bfcff7fb446f4033f81f3b9f26934ded0e77705699fea748204658b3b7  
    web  
    android  

https://hub.docker.com/r/openruntimes/flutter  
    android   

https://hub.docker.com/layers/adamantium/flutter/latest/images/sha256-f2d57ba7f477c3be047858a49cf98f366f29ab3eb432e0985df81d0aa3c68093  
    android  

https://hub.docker.com/layers/metaflowltd/flutter/latest/images/sha256-3b2c4c17602190e3c0a6e709d54918dd9c85fbccbd1a781b976d9016d8a09e2d  
    android            

https://hub.docker.com/layers/gableroux/flutter/latest/images/sha256-05a5f05f6d1d5d8ae58a49c977bf0326e6534bf7ea17c43925b97c11a8ae0e2a  


### TODO 其他：  
    [] 能否设置全局gradle环境？  
    [Y] 加速：--device /dev/kvm --device /dev/dri:/dev/dri -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY  
    [Y] 能否开启模拟器？   
    [Y]     能否使用模拟器运行程序？  
    [Y]     能否调试？  
    [] 能否运行鸿蒙app？   
