FROM frolvlad/alpine-gxx AS builder

RUN apk add --no-cache automake \
    autoconf \
    bison \
    build-base \ 
    curl \
    git \
    libtool \
    pulseaudio \
    pulseaudio-dev \
    python3-dev \
    swig \
    tar && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

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
