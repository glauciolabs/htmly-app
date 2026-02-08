FROM php:8.2.30-apache-trixie

LABEL maintainer="glauciolabs"

ARG HTMLY_VERSION=v3.1.1
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential pkg-config \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev zip unzip libonig-dev libxml2-dev libicu-dev git openssh-client ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*


RUN docker-php-ext-install mbstring
RUN docker-php-ext-install zip
RUN docker-php-ext-install intl
RUN docker-php-ext-configure gd --with-jpeg --with-freetype --without-avif --without-webp \
    && MAKEFLAGS=-j1 docker-php-ext-install gd

RUN a2enmod rewrite

RUN wget -O /tmp/htmly.tar.gz https://github.com/danpros/htmly/archive/refs/tags/${HTMLY_VERSION}.tar.gz \
    && tar -xzf /tmp/htmly.tar.gz -C /var/www/html/ --strip-components 1 \
    && rm -rf /tmp/htmly* \
    && rm -rf /var/www/html/config/config.ini

RUN chown -R www-data:www-data /var/www/html

ENV HOME=/var/www/html
LABEL org.opencontainers.image.title="htmly" \
      org.opencontainers.image.description="HTMLy blog container with git-synced content and auto-reload probes" \
      org.opencontainers.image.authors="glauciolabs" \
      org.opencontainers.image.source="https://github.com/glauciolabs/htmly-app" \
      org.opencontainers.image.version="${HTMLY_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="php:8.2.30-apache-trixie"

COPY scripts/check-commit.sh /usr/local/bin/check-commit.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/check-commit.sh

USER www-data

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
