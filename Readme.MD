# Purpose

A spot fleet cloudformation script that allows you to make spot request for gpu enabled ecs instances, it includes userdata that 
1. helps installs the gpu driver and the nvidia container runtime
2. configures docker daemon to use the nvidia container runtime       

# Benefit

1. Instead of being charged the full price, spot instances comes at a discounted price, e.g. the on demand price can be 0.97 and the spot price can be 0.30

2. Allows docker container of any distribution to be used to run gpu load

3. Leverage existing container management platform in AWS ( ECS )

# Key implmentation details

## Runtime
Early attempts to allow containers to gain access to gpu were done by a wrapper called `nvidia-docker`. There is no capability in ECS that provide the capability to swap `docker` with this wrapper. Docker allows a runtime to be specified and the nvidia container runtime recently released is one such runtime (https://github.com/NVIDIA/nvidia-docker/wiki/Usage), e.g. 

    `docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi`

While this eliminates the need for `nvidia-docker`, there is still no capability to specify the runtime parameter when starting up task. The way to overcome this is to define the runtime in `/etc/docker/daemon.json` like this :

```
    {
    "default-runtime": "nvidia",
    "runtimes": {"nvidia": {"path": "/usr/bin/nvidia-container-runtime","runtimeArgs": []}}
    }          
```

## Driver & nvidia container runtime
In order to install the driver, gcc and kernel-devel needs to be install. However a pre-requisite to to ensure the kernel is updated. This will ensure kernel update : 

```
    yum update -y
```

Kernel update necessitate a reboot. I am a novice in all things linux and aws, so my solution to this may be naive - create a script that run once and schedule it to run on startup. Below is such a script :


```
    echo "installing gpu driver and pre-requisite" >> /etc/onetime.log
    yum install -y gcc 
    export kernel_devel_pkg="kernel-devel-\$(uname -r)"                 
    echo "kernel-devel package - \$kernel_devel_pkg"
    yum install -y \$kernel_devel_pkg                 
    export version=384.111
    export arch=\$(uname -m)
    export driverSource="http://us.download.nvidia.com/XFree86/Linux-\$arch/\$version/NVIDIA-Linux-\$arch-\$version.run"
    echo "downloading from \$driverSource"
    curl -fS -o /etc/downloads/NVIDIA-Linux-\$arch-\$version.run \$driverSource 
    chmod a+x /etc/downloads/NVIDIA-Linux-\$arch-\$version.run 
    bash /etc/downloads/NVIDIA-Linux-\$arch-\$version.run -silent
    nvidia-persistenced
    nvidia-smi --auto-boost-default=0
    nvidia-smi -ac 2505,875
    curl -s -L https://nvidia.github.io/nvidia-container-runtime/amzn1/nvidia-container-runtime.repo | tee /etc/yum.repos.d/nvidia-container-runtime.repo
    yum install nvidia-container-runtime -y
    /sbin/service docker restart
    /sbin/start ecs  
    echo "echo \"nothing to do\" >> /etc/onetime.log" > /usr/local/bin/onetime.sh 
```

# Artifacts

1. gpuecsspotfleet.yml - Cloudformation script to create an ecs instance 
2. Dockerfile - an example cuda/gpu aware container, this would be the application or the job and the image build from this should be made available in a docker repository
3. service.yml - Cloudformation script to create a service (from an image built from the Dockerfile) and place it in the ecs cluster create by gpuecsspotfleet.yml
4. gputest.ipynb - a jupyter notebook to verify that gpu is being used by the container 

# Dependencies

1. In gpuecsspotfleet.yml, a subnet export value ( from another cloudformation ) is required (search for  `!ImportValue MySubNet`)
2. service.yml is dependent on the cluster that is created by the gpuecsspotfleet.yml

