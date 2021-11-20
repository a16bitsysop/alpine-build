ARG DVER=edge
ARG NME=builder

##################################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

RUN apk add --no-cache -u alpine-conf alpine-sdk atools pax-utils findutils gdb git sudo \
&&  echo /tmp/packages >> /etc/apk/repositories

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild \
&&  echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&&  echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME} \
&&  sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

USER ${NME}
RUN abuild-keygen -a -i -n \
&&  mkdir "$HOME"/packages

##################################################################################################
FROM buildbase AS buildust
ARG NME

COPY just-build.sh /usr/local/bin/

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

RUN sudo apk update \
&&  just-build.sh

##################################################################################################
FROM buildbase AS buildtools
ARG NME

COPY just-build.sh /usr/local/bin/
COPY --from=buildust /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

RUN sudo apk update \
&&  just-build.sh
