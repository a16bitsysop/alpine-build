ARG DVER=edge
ARG NME=builder

##################################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

# install abuild deps and add /tmp/packages to repositories
RUN apk add --no-cache -u alpine-conf alpine-sdk atools findutils gdb git pax-utils sudo \
&&  echo /tmp/packages >> /etc/apk/repositories

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild \
&&  echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&&  echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME} \
&&  sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

COPY --chmod=755 just-build.sh /usr/local/bin/

# switch to build user create keys and copy to global folder
USER ${NME}
RUN abuild-keygen -a -i -n
RUN mkdir "$HOME"/packages
RUN ls -lah "$HOME"/.abuild
RUN ls -lah /etc/apk/keys
RUN foobar
##################################################################################################
FROM buildbase AS buildust
ARG NME

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

RUN sudo apk update \
&&  just-build.sh

##################################################################################################
FROM buildbase AS buildtools
ARG NME

COPY --from=buildust /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

RUN sudo apk update \
&&  just-build.sh
