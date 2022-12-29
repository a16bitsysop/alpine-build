ARG DVER=edge
ARG NME=devuser

##################################################################################################
FROM registry.gitlab.com/a16bitsysop/alpine-dev-local/main:latest AS buildbase
ARG NME

# install extra packages and add /tmp/pkg to repositories
RUN apk add --no-cache -u findutils gdb \
&&  echo /tmp/pkg >> /etc/apk/repositories

# create keys and copy to global folder, switch to build user
RUN su ${NME} -c "abuild-keygen -a -i -n"
USER ${NME}
WORKDIR /tmp/pkg

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

RUN pwd && ls -RC
RUN abuild checksum
RUN abuild deps
RUN echo "Arch is: $(abuild -A)" && abuild -K -P /tmp/pkg

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
COPY ${APORT} ./
RUN sudo chown -R ${NME}:${NME} ../${APORT}

RUN pwd && ls -RC
RUN abuild checksum
RUN abuild deps
RUN echo "Arch is: $(abuild -A)" && abuild -K -P /tmp/pkg
