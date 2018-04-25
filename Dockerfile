FROM tensorflow/tensorflow:latest-gpu-py3
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24
RUN su -c "echo 'deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main' > /etc/apt/sources.list.d/git.list"
RUN apt-get update 
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get install git -y
RUN apt-get install libsm6 -y
RUN apt-get install libxrender1 -y
RUN pip install --upgrade pip
RUN pip3 install opencv-python
RUN pip3 install keras  
RUN pip3 install scikit-image
RUN pip3 install scipy
RUN pip3 install cython