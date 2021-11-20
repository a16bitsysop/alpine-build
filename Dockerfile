ARG DVER=edge
ARG NME=builder

##########################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

# install packages needed for abuild
RUN apk add --no-cache -u alpine-conf alpine-sdk atools doas findutils gdb git pax-utils

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild && addgroup ${NME} tty \
&& echo "permit nopass ${NME} as root" > /etc/doas.d/doas.conf \
&& sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf \
&& echo /tmp/packages >> /etc/apk/repositories

COPY --chmod=755 just-build.sh /usr/local/bin/

ENV SUDO doas
USER ${NME}
# create build keys and copy public key so can install without allow untrusted
RUN  abuild-keygen -a -i -n \
&& doas cp /home/${NME}/.abuild/*.rsa.pub /etc/apk/keys/ \
&& mkdir ~/packages

#########################################################################################
FROM buildbase AS buildust
ARG NME

WORKDIR /tmp
COPY lttng-ust ./

RUN doas apk update
RUN just-build.sh

#########################################################################################
FROM buildbase AS buildtools
ARG NME

COPY --chmod=644 --from=buildust /tmp/packages/* /tmp/packages/
RUN find /tmp/packages -type f

WORKDIR /tmp
COPY lttng-tools ./

RUN doas apk update
RUN just-build.sh
