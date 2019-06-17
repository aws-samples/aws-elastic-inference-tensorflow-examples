FROM debian 

RUN apt-get update -y && apt-get upgrade -y

RUN apt install -y curl

RUN echo 'deb http://ftp.de.debian.org/debian testing main' >> /etc/apt/sources.list
RUN echo 'APT::Default-Release "stable";' | tee -a /etc/apt/apt.conf.d/00local
RUN echo "tango-common tango-common/tango-host string ${TANGOSERVER}:20000" | debconf-set-selections


RUN apt-get update -y && apt-get install -y  \
	git   \
	nano  \
	vim  \
	wget \
	protobuf-compiler \
	python-pil \
	python-lxml \
	libav-tools \
	make \
	build-essential \
	libssl-dev \
	zlib1g-dev \
	libbz2-dev \
	libreadline-dev \
	libsqlite3-dev \
	llvm \
	libncurses5-dev \
	libncursesw5-dev \
	xz-utils \
	tk-dev \
	unzip \
	libsm6 \
	libxext6 \
	libfontconfig1 \
	libxrender1 


RUN wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u11_amd64.deb \
	&& dpkg -i libssl1.0.0_1.0.1t-1+deb8u11_amd64.deb

RUN wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz \
	&& tar xvf Python-3.6.4.tgz \
	&& cd Python-3.6.4 \
	&& ./configure --enable-optimizations \
	&& make -j8 \
	&& make altinstall

RUN wget https://bootstrap.pypa.io/get-pip.py \
	&& python3.6 get-pip.py \
	&& rm get-pip.py \
	&& cd /usr/local/bin \
	&& rm -f easy_install \
	&& rm -f pip \
	&& rm -f pydoc \
	&& rm -f python \
	&& ln -s easy_install-3.6 easy_install \
  	&& ln -s pip3.6 pip \
	&& ln -s /usr/bin/pydoc3.6 pydoc \
	&& ln -s /usr/bin/python3.6 python

WORKDIR /

RUN pip3.6 install --upgrade \
	pillow \
        jupyter \
	matplotlib \
	opencv-python \
	awscli \
	ffmpeg-python	


RUN aws s3 cp s3://amazonei-tensorflow/tensorflow/v1.13/ubuntu/latest/tensorflow-1-13-1-ubuntu-ei-1-1-python36.tar.gz . --no-sign-request \
	&& tar xvzf tensorflow-1-13-1-ubuntu-ei-1-1-python36.tar.gz \
	&& pip3.6 install tensorflow-1-13-1-ubuntu-ei-1-1-python36/*.whl

RUN git clone https://github.com/tensorflow/models.git

WORKDIR /models/research

RUN curl -L -o protobuf.zip https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip \
    && unzip protobuf.zip \
    && ./bin/protoc object_detection/protos/*.proto --python_out=.

RUN echo "export PYTHONPATH=${PYTHONPATH}:`pwd`:`pwd`/slim" >> ~/.bashrc

COPY artifacts/* /models/research/object_detection/

WORKDIR /models/research/object_detection/

RUN wget http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet50_coco_2018_01_28.tar.gz \
	&& tar xvzf faster_rcnn_resnet50_coco_2018_01_28.tar.gz

ENTRYPOINT ["jupyter", "notebook", "--ip=\"0.0.0.0\"", "--allow-root"]
