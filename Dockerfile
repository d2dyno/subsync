FROM frolvlad/alpine-python3 as builder

RUN apk add build-base

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

mkdir -p /app \
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
