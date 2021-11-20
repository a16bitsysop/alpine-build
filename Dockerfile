ARG DVER=edge
ARG NME=builder

##########################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

# install packages needed for abuild
RUN apk add --no-cache -u alpine-conf alpine-sdk atools findutils gdb git pax-utils sudo

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild && addgroup ${NME} tty \
&& sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf \
&& echo /tmp/packages >> /etc/apk/repositories

COPY --chmod=755 just-build.sh /usr/local/bin/

USER ${NME}
# create build keys and copy public key so can install without allow untrusted
RUN  abuild-keygen -a -i -n \
&& doas cp /home/${NME}/.abuild/*.rsa.pub /etc/apk/keys/ \
&& mkdir "$HOME"/packages \
&& ls -lah "$HOME"
USER root

#########################################################################################
FROM buildbase AS buildust
ARG NME

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

USER ${NME}
RUN doas apk update
RUN just-build.sh

#########################################################################################
FROM buildbase AS buildtools
ARG NME

COPY --chmod=644 --from=buildust /tmp/packages/* /tmp/packages/
RUN find /tmp/packages -type f

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

USER ${NME}
RUN doas apk update
RUN just-build.sh
