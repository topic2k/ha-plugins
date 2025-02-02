ARG BUILD_FROM
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT

FROM $BUILD_FROM
ENV LANG C.UTF-8


RUN echo "BUILD_FROM: $BUILD_FROM"
RUN echo "TARGETPLATFORM: $TARGETPLATFORM"
RUN echo "TARGETOS: $TARGETOS"
RUN echo "TARGETARCH: $TARGETARCH"
RUN echo "TARGETVARIANT: $TARGETVARIANT"
RUN echo "BUILDPLATFORM: $BUILDPLATFORM"
RUN echo "BUILDOS: $BUILDOS"
RUN echo "BUILDARCH: $BUILDARCH"
RUN echo "BUILDVARIANT: $BUILDVARIANT"


RUN apt-get update
RUN apt-get install -y build-essential git swig python3 python3-dev python3-pip ffmpeg

RUN pip3 install pydub requests PyYAML typing_extensions

WORKDIR /tmp
RUN set -xe \
    && git clone --depth 1 --branch 2.13 https://github.com/pjsip/pjproject.git \
    && cd pjproject \
    && ./configure --enable-shared --disable-libwebrtc \
    && make \
    && make dep \
    && make install \
    && cd pjsip-apps/src/swig \
    && make python \
    && make -C python install \
    && ldconfig \
    && rm -rf /tmp/pjproject

COPY run.sh /
RUN chmod a+x /run.sh

COPY src/ /ha-sip/

CMD [ "/run.sh" ]
