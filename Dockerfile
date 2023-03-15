ARG NME=devuser

##################################################################################################
FROM registry.gitlab.com/a16bitsysop/alpine-dev-local/main:latest AS buildbase
ARG NME

USER root
# install extra packages
RUN apk add --no-cache -u findutils gdb
RUN echo "/tmp/pkg" >>/etc/apk/repositories

USER ${NME}
# create keys and copy to global folder
RUN abuild-keygen -a -i -n

##################################################################################################
FROM buildbase AS builddep
ARG NME
ENV APORT=lttng-ust
ENV REPO=main

# pull source on host with
# pull-apk-source.sh main/lttng-ust

# copy aport folder into container
WORKDIR /tmp/${APORT}
COPY --chown=${NME}:${NME} ${APORT} ./

RUN pwd && ls -RC
RUN abuild checksum
RUN abuild deps
RUN echo "Arch is: $(abuild -A)" && abuild -P /tmp/pkg

##################################################################################################
FROM buildbase AS buildaport
ARG NME
ENV APORT=lttng-tools
ENV REPO=community

# copy built packages from previous step
COPY --from=builddep /tmp/pkg/* /tmp/pkg/
RUN ls -RC /tmp/pkg

# pull source on host with
# pull-apk-source.sh community/lttng-tools

# copy aport folder into container
WORKDIR /tmp/${APORT}
COPY --chown=${NME}:${NME} ${APORT} ./

RUN pwd && ls -RC
RUN abuild checksum
RUN abuild deps
RUN echo "Arch is: $(abuild -A)" && abuild -K -P /tmp/pkg
