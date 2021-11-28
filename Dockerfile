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

COPY --chmod=755 just-build.sh pull-apk-source.sh /usr/local/bin/

# create keys and copy to global folder, switch to build user
RUN su ${NME} -c "abuild-keygen -a -i -n"
USER ${NME}
RUN mkdir "$HOME"/packages

##################################################################################################
FROM buildbase AS builddep
ARG NME
ENV APORT=lttng-ust
ENV REPO=main

# copy aport folder into container
#WORKDIR /tmp
#COPY --chown=${NME}:${NME} ${APORT} ./${APORT}

# or pull source
RUN pull-apk-source.sh ${REPO}/${APORT}

RUN just-build.sh ${APORT}

##################################################################################################
FROM buildbase AS buildaport
ARG NME
ENV APORT=lttng-tools
ENV REPO=community

# copy built packages from previous step
COPY --from=builddep /tmp/packages/* /tmp/packages/
RUN ls -lah /tmp/packages

# copy aport folder into container
#WORKDIR /tmp
#COPY --chown=${NME}:${NME} ${APORT} ./${APORT}

# or pull source
RUN pull-apk-source.sh ${REPO}/${APORT}

RUN just-build.sh ${APORT}
