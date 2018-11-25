FROM prom/prometheus

USER root
ADD bin/curl-7.30.0.ermine.tar.bz2 .

RUN mv curl-7.30.0.ermine/curl.ermine /bin/curl \
    && rm -Rf curl-7.30.0.ermine

USER nobody
ADD config/prometheus.yml /etc/prometheus/
ADD src/entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT [ "/bin/entrypoint.sh" ]
CMD        [ "--debug" ]
