FROM prom/prometheus

USER root
ADD bin/curl-7.30.0.ermine.tar.bz2 .

RUN mv curl-7.30.0.ermine/curl.ermine /bin/curl \
    && rm -Rf curl-7.30.0.ermine

# Capture SIGTERM from an orchestrator so we can reliably use entrypoint.sh
# Using tini https://github.com/krallin/tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /bin/tini
RUN chmod +x /bin/tini

USER nobody
ADD config/prometheus.yml /etc/prometheus/
ADD src/entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT ["/bin/tini", \
            "--", \
            "sh", \
            "/bin/entrypoint.sh" ]

CMD        [ "" ]
