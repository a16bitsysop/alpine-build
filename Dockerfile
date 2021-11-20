ARG DVER=edge
ARG NME=builder

##################################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

RUN apk add --no-cache -u alpine-conf alpine-sdk atools pax-utils findutils gdb git sudo

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild \
&&  mkdir /home/${NME}/packages && chown ${NME}:${NME} /home/${NME}/packages

RUN echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&&  echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME}

RUN su ${NME} -c "abuild-keygen -a -i -n"
RUN sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

##################################################################################################
FROM buildbase AS buildust
ARG NME

COPY just-build.sh /usr/local/bin/

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

RUN apk update
USER ${NME}
RUN just-build.sh

##################################################################################################
FROM buildbase AS buildtools
ARG NME

COPY just-build.sh /usr/local/bin/
COPY --from=buildust /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

RUN echo /tmp/packages >> /etc/apk/repositories

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

RUN apk update
USER ${NME}
RUN just-build.sh
