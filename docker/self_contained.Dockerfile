ARG FDB_VERSION=7.1.42

FROM us-docker.pkg.dev/dev-staging-308107/devbox-containers/foundationdb:${FDB_VERSION}-pkg as built_fdb

FROM clementpang/lionrock-foundationdb-base:latest

WORKDIR /

RUN mkdir -p /var/fdb/logs

RUN apt-get update && apt-get install tini -y

# Install foundationdb clients
COPY --from=built_fdb /fdb-build/packages/foundationdb-clients*.deb foundationdb-clients.deb
COPY --from=built_fdb /fdb-build/packages/lib/libfdb_java.so libfdb_java.so
RUN dpkg -i foundationdb-clients.deb
RUN rm foundationdb-clients.deb

# We need to not create a new foundationdb database when installing foundationdb-server.deb
# COPY init_foundationdb.cluster.sh .
# COPY run_foundationdb.sh .
COPY fdb_single.bash .
RUN chmod u+x fdb_single.bash

ENV FDB_PORT 4500
ENV FDB_CLUSTER_FILE /var/fdb/fdb.cluster
ENV FDB_NETWORKING_MODE container
ENV FDB_COORDINATOR ""
ENV FDB_COORDINATOR_PORT 4500
ENV FDB_CLUSTER_FILE_CONTENTS ""
ENV FDB_PROCESS_CLASS unset
# RUN chmod u+x init_foundationdb.cluster.sh
# RUN chmod u+x run_foundationdb.sh
# RUN /init_foundationdb.cluster.sh

# Install foundationdb server
COPY --from=built_fdb /fdb-build/packages/foundationdb-server*.deb foundationdb-server.deb
RUN dpkg -i foundationdb-server.deb
RUN rm foundationdb-server.deb

EXPOSE 4500

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/fdb_single.bash"]