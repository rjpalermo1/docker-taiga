FROM python:3.4
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        git \
        nano \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

COPY taiga-back /usr/src/taiga-back
COPY taiga-front-dist/ /usr/src/taiga-front-dist
COPY docker-settings.py /usr/src/taiga-back/settings/docker.py
COPY conf/locale.gen /etc/locale.gen

# Setup symbolic links for configuration files
RUN mkdir -p /taiga
COPY conf/taiga/local.py /taiga/local.py
COPY conf/taiga/conf.json /taiga/conf.json
RUN ln -s /taiga/local.py /usr/src/taiga-back/settings/local.py
RUN ln -s /taiga/conf.json /usr/src/taiga-front-dist/dist/conf.json

# Backwards compatibility
RUN mkdir -p /usr/src/taiga-front-dist/dist/js/
RUN ln -s /taiga/conf.json /usr/src/taiga-front-dist/dist/js/conf.json

WORKDIR /usr/src/taiga-back

RUN pip install --no-cache-dir -r requirements.txt

RUN echo "LANG=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_TYPE=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_MESSAGES=POSIX" >> /etc/default/locale
RUN echo "LANGUAGE=en" >> /etc/default/locale

ENV LANG en_US.UTF-8
ENV LC_TYPE en_US.UTF-8

ENV TAIGA_SSL True
ENV TAIGA_HOSTNAME dev.ipayengine.com
ENV TAIGA_SECRET_KEY "sdkfl7Hyf6352vvsg5hheyGcasgpPi97ccz"
ENV TAIGA_DB_NAME postgres
ENV TAIGA_DB_USER postgres

RUN python manage.py collectstatic --noinput

RUN locale -a

EXPOSE 8044:8044 8443:8443

COPY checkdb.py /checkdb.py
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
