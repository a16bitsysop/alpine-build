ARG DVER=edge
ARG BNME=buider

######################################################################################
FROM alpine:${DVER} AS buildbase
ENV NME ${BNME}

# install packages needed for abuild
RUN apk add --no-cache -u alpine-conf alpine-sdk pax-utils atools git sudo gdb findutils

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild && addgroup ${NME} tty \
&& mkdir /home/${NME}/packages && chown ${NME}:${NME} /home/${NME}/packages \
&& echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&& echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME} \
&& sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

# create build keys and copy public key so can install without allow untrusted
RUN  su ${NME} -c "abuild-keygen -a -i -n" \
&& cp /home/${NME}/.abuild/*.rsa.pub /etc/apk/keys/

COPY --chmod=755 just-build.sh /usr/local/bin/

######################################################################################
FROM buildbase AS buildust
ENV NME ${BNME}

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

RUN apk update
USER ${NME}
RUN just-build.sh

######################################################################################
FROM buildbase AS buildtools
ENV NME ${BNME}

COPY --chmod=644 --from=buildust /tmp/packages/* /tmp/packages/
RUN find /tmp/packages -type f \
&& echo /tmp/packages >> /etc/apk/repositories

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

RUN apk update
USER ${NME}
RUN just-build.sh
