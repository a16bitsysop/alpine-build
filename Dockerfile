ARG DVER=edge
ARG NME=builder

##################################################################################################
FROM alpine:${DVER} AS buildbase
ARG NME

# install abuild deps and add /tmp/packages to repositories
RUN apk add --no-cache -u alpine-conf alpine-sdk atools findutils gdb git pax-utils sudo \
&&  echo /tmp/pkg >> /etc/apk/repositories

# setup build user
RUN adduser -D ${NME} && addgroup ${NME} abuild \
&&  echo "Defaults  lecture=\"never\"" > /etc/sudoers.d/${NME} \
&&  echo "${NME} ALL=NOPASSWD : ALL" >> /etc/sudoers.d/${NME} \
&&  sed "s/ERROR_CLEANUP.*/ERROR_CLEANUP=\"\"/" -i /etc/abuild.conf

COPY just-build.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/just-build.sh

# create keys and copy to global folder, switch to build user
RUN su ${NME} -c "abuild-keygen -a -i -n"
USER ${NME}

##################################################################################################
FROM buildbase AS builddep
ARG NME
ENV APORT=lttng-ust
ENV REPO=main

# pull source on host with
# pull-apk-source.sh main/lttng-ust

# copy aport folder into container
WORKDIR /tmp/${APORT}
COPY ${APORT} ./
RUN sudo chown -R ${NME}:${NME} ../${APORT}

RUN pwd && ls -lah
RUN abuild checksum
RUN abuild deps
RUN just-build.sh

##################################################################################################
FROM buildbase AS buildaport
ARG NME
ENV APORT=lttng-tools
ENV REPO=community

# copy built packages from previous step
COPY --from=builddep /tmp/pkg/* /tmp/pkg/
RUN ls -lah /tmp/pkg

# pull source on host with
# pull-apk-source.sh community/lttng-tools

# copy aport folder into container
WORKDIR /tmp/${APORT}
COPY ${APORT} ./
RUN sudo chown -R ${NME}:${NME} ../${APORT}

RUN pwd && ls -lah
RUN abuild checksum
RUN abuild deps
RUN just-build.sh
