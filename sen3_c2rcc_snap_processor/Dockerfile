#FROM core.harbor.dev.eoss-cloud.it/com.cgi.eoss.platform/esa-snap:10
FROM cesarero/esa-snap:10

LABEL maintainer="CGI"

RUN apt-get update && apt-get install --yes --no-install-recommends \
    jq zip unzip gdal-bin python3-gdal python3-venv\
    && rm -rf /var/lib/apt/lists/*

ARG WORKER_DIR=/home/worker
ARG IN_DIR="$WORKER_DIR/workDir/inDir"
ARG OUT_DIR="$WORKER_DIR/workDir/outDir"
ARG PROC_DIR="$WORKER_DIR/procDir"

RUN mkdir -p $IN_DIR
RUN mkdir -p $OUT_DIR
RUN mkdir -p $PROC_DIR

COPY * ${PROC_DIR}/

# Enable venv
RUN python3 -m venv $PROC_DIR/venv
RUN . $PROC_DIR/venv/bin/activate \
    && pip3 install -r $PROC_DIR/requirements.txt \
    && deactivate

RUN chmod +x $PROC_DIR/workflow.sh

ENTRYPOINT ["/home/worker/procDir/workflow.sh"]


