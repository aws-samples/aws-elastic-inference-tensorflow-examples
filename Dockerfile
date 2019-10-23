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
	make \
	ffmpeg \
        multiarch-support \
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

RUN wget http://security-cdn.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb \
	&& dpkg -i libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb

RUN apt-get update && apt-get install -y --no-install-recommends \
		tcl \
		tk \
	&& rm -rf /var/lib/apt/lists/*

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.6.0

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 9.0.1

RUN set -ex \
	&& buildDeps=' \
		tcl-dev \
		tk-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& gpg --batch --verify python.tar.xz.asc python.tar.xz \
	&& rm -r "$GNUPGHOME" python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz \
	\
	&& cd /usr/src/python \
	&& ./configure \
		--enable-loadable-sqlite-extensions \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	\
# explicit path to "pip3" to ensure distribution-provided "pip3" cannot interfere
	&& if [ ! -e /usr/local/bin/pip3 ]; then : \
		&& wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
		&& python3 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" \
		&& rm /tmp/get-pip.py \
	; fi \
# we use "--force-reinstall" for the case where the version of pip we're trying to install is the same as the version bundled with Python
# ("Requirement already up-to-date: pip==8.1.2 in /usr/local/lib/python3.6/site-packages")
# https://github.com/docker-library/python/pull/143#issuecomment-241032683
	&& pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION"


# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
	&& { [ -e easy_install ] || ln -s easy_install-* easy_install; } \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

WORKDIR /

RUN pip3.6 install --upgrade \
	pillow \
        jupyter \
	matplotlib \
	opencv-python \
	awscli \
	ffmpeg-python	


RUN aws s3 cp s3://amazonei-tensorflow/tensorflow/v1.13/ubuntu/archive/tensorflow-1-13-1-ubuntu-ei-1-1-python36.tar.gz . --no-sign-request \
	&& tar xvzf tensorflow-1-13-1-ubuntu-ei-1-1-python36.tar.gz \
	&& pip3 install tensorflow-1-13-1-ubuntu-ei-1-1-python36/*.whl

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
