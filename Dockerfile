FROM alpine:edge AS buildbase

ENV NME builder
ENV FULL "builder builder"
ENV EMAIL "build@build"

RUN apk add --no-cache -u alpine-conf alpine-sdk pax-utils atools git sudo gdb findutils

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild && addgroup ${NME} tty \
&& mkdir /home/${NME}/packages && chown ${NME}:${NME} /home/${NME}/packages \
&& mkdir -p /var/cache/distfiles \
&& chgrp abuild /var/cache/distfiles \
&& chmod g+w /var/cache/distfiles

RUN echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&& echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME}

RUN  su ${NME} -c "abuild-keygen -a -i -n"
RUN echo "PACKAGER=\"${FULL} <${EMAIL}>\"" >> /etc/abuild.conf \
&& echo 'MAINTAINER="$PACKAGER"' >> /etc/abuild.conf \
&& sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

##
FROM buildbase AS buildust
ENV NME builder

COPY just-build.sh /usr/local/bin/

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-ust ./

RUN apk update
USER ${NME}
RUN just-build.sh

##
FROM buildbase AS buildtools
ENV NME builder

COPY just-build.sh /usr/local/bin/
COPY --from=buildust /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

RUN echo /tmp/packages >> /etc/apk/repositories

WORKDIR /tmp
COPY --chown=${NME}:${NME} lttng-tools ./

RUN apk update
USER ${NME}
RUN just-build.sh
