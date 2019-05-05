FROM frolvlad/alpine-gxx AS builder

RUN apk add --no-cache alsa-lib-dev \
    automake \
    autoconf \
    bison \
    build-base \ 
    curl \
    git \
    libtool \
    python3-dev \
    swig \
    tar \
    wget && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

WORKDIR /build

RUN wget https://sourceforge.net/projects/cmusphinx/files/sphinxbase/5prealpha/sphinxbase-5prealpha.tar.gz/download -O sphinxbase.tar.gz \
	&& tar -xzvf sphinxbase.tar.gz \
        && cd /build/sphinxbase-5prealpha \
	&& ./configure --enable-fixed \
	&& make \
	&& make install

RUN wget https://sourceforge.net/projects/cmusphinx/files/pocketsphinx/5prealpha/pocketsphinx-5prealpha.tar.gz/download -O pocketsphinx.tar.gz \
	&& tar -xzvf pocketsphinx.tar.gz \
        && cd /build/pocketsphinx-5prealpha \
	&& ./configure \
	&& make \
	&& make install

ENV FFMPEGVER https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz

RUN mkdir -p /build/ffmpeg \
	&& cd /build/ffmpeg \
	&& wget "$FFMPEGVER" \
	&& tar xf ffmpeg-release-amd64-static.xz

ENV FFMPEG_DIR /build/ffmpeg-release-amd64-static
ENV SPHINXBASE_DIR /build/sphinxbase-5prealpha
ENV POCKETSPHINX_DIR /build/pocketsphinx-5prealpha
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
