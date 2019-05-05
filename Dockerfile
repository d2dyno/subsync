FROM lsiobase/alpine:3.9 AS builder

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	autoconf \
	automake \
	bison \
	freetype-dev \
	g++ \
	gcc \
	jpeg-dev \
	lcms2-dev \
	libffi-dev \
	libpng-dev \
	libtool \
	libwebp-dev \
	linux-headers \
	make \
	openjpeg-dev \
	openssl-dev \
	python3-dev \
	tiff-dev \
	zlib-dev && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	curl \
	freetype \
	git \
	lcms2 \
	libjpeg-turbo \
	libwebp \
	openjpeg \
	openssl \
	p7zip \
	py3-lxml \
	python3 \
	tar \
	tiff \
	unrar \
	unzip \
	vnstat \
	wget \
	xz \
	zlib && \
 echo "**** use ensure to check for pip and link /usr/bin/pip3 to /usr/bin/pip ****" && \
 python3 -m ensurepip && \
 rm -r /usr/lib/python*/ensurepip && \
 if \
	[ ! -e /usr/bin/pip ]; then \
	ln -s /usr/bin/pip3 /usr/bin/pip ; fi && \
 echo "**** install pip packages ****" && \
 pip install --no-cache-dir -U \
	pip \
	setuptools && \
 pip install -U \
	configparser \
	ndg-httpsclient \
	notify \
	paramiko \
	pillow \
	psutil \
	pyopenssl \
	requests \
	setuptools \
	urllib3 \
	virtualenv && \
 echo "**** clean up ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/root/.cache \
	/tmp/*

WORKDIR /build

RUN git clone https://github.com/cmusphinx/sphinxbase.git sphinxbase \
	&& cd /build/sphinxbase \
	&& ./autogen.sh \
	&& ./configure \
	&& make \
	&& make install

RUN git clone https://github.com/cmusphinx/pocketsphinx.git pocketsphinx \
	&& cd /build/pocketsphinx \
	&& ./configure \
	&& make clean all \
	&& make check \
	&& make install

ENV FFMPEGVER https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz

RUN mkdir -p /build/ffmpeg \
	&& cd /build/ffmpeg \
	&& curl "$FFMPEGVER" \
	&& tar xf $(basename "$FFMPEGVER")

ENV FFMPEG_DIR /build/ffmpeg
ENV SPHINXBASE_DIR /build/sphinxbase
ENV POCKETSPHINX_DIR /build/pocketsphinx
ENV USE_PKG_CONFIG yes

RUN mkdir -p /app \
	&& git clone https://github.com/sc0ty/subsync.git /app/subsync \
	&& pip install -r /app/subsync/requirements.txt \
	&& cd /app/subsync/gizmo \
	&& python setup.py build

FROM frolvlad/alpine-python3

COPY --from=builder /app .

RUN pip install -r /app/subsync/requirements.txt \
	&& cd /app/subsync/gizmo \
	&& python setup.py install

CMD ["python subsync.py"}
