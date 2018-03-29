FROM alpine:edge

# Create user www-data
RUN addgroup -g 82 -S www-data && \
    adduser -u 82 -D -S -G www-data nginx

# Install PHP7, Pygments and Git
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --update add \
      php7 \
      php7-bcmath \
      php7-ctype \
      php7-curl \
      php7-dom \
      php7-exif \
      php7-fpm \
      php7-gd \
      php7-gettext \
      php7-gmp \
      php7-iconv \
      php7-intl \
      php7-json \
      php7-mbstring \
      php7-mcrypt \
      php7-mysqli \
      php7-opcache \
      php7-openssl \
      php7-pcntl \
      php7-pdo \
      php7-pdo_mysql \
      php7-phar \
      php7-session \
      php7-tidy \
      php7-tokenizer \
      php7-simplexml \
      php7-xdebug \
      php7-xml \
      php7-xmlreader \
      php7-xmlrpc \
      php7-zip \
      php7-zlib \
      bash \
      curl \
	    git \
      mysql-client \
      openssl \
      openssh \
      py-pygments \
      unzip && \
    rm -rf /var/cache/apk/*

    RUN apk --update add \
        autoconf \
        build-base \
        libtool \
        php7-pear \
        php7-dev \
        alpine-sdk && \
        sed -i "s/exec \$PHP -C -n -q/exec \$PHP -C -q/g" /usr/bin/pecl && \
        printf "\n" | pecl install apcu apcu_bc-beta && \
        echo "extension=apcu.so" > /etc/php7/conf.d/apcu.ini && \
        echo "extension=apc.so"  > /etc/php7/conf.d/z_apc.ini && \
        sed -ie 's/-n//g' /usr/bin/pecl && \
            apk del --purge \
            alpine-sdk \
            autoconf \
            build-base \
            libtool \
            php7-pear \
            php7-dev \
            alpine-sdk && \
        rm -rf /var/cache/apk/*

RUN rm -rf /etc/php7/php-fpm.d \
    && mkdir -p /srv \
    && mkdir -p /data \
    && mkdir -p /repo \
    && mkdir -p /usr/local/sbin \
    && mkdir -p /var/tmp/phd/log \
    && mkdir -p /var/logs/php-fpm \
    && ln -fs /proc/self/fd/2 /var/tmp/phd/log/daemons.log

# Install Composer
ENV COMPOSER_VERSION 1.4.2
RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
  chmod +x /usr/local/bin/composer

  # Speed up composer
  RUN composer global require "hirak/prestissimo:^0.3"

# Install Drush using Composer.
ENV DRUSH_VERSION 8.1.11
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && \
    cd /usr/local/src/drush && \
    git checkout ${DRUSH_VERSION} && \
    ln -s /usr/local/src/drush/drush /usr/bin/drush && \
    composer install
RUN drush --version

# Create workdir
RUN mkdir -p /var/www/html && \
    chown -R nginx:www-data /var/www && \
    chmod -R 774 /var/www && \
    umask 774 /var/www

WORKDIR /var/www/html/web

# COPY configuration files.
COPY conf/fpm.conf /etc/php7/php-fpm.conf
COPY conf/php.ini /etc/php7/php.ini
COPY conf/conf.d/xdebug.ini /etc/php7/conf.d/xdebug.ini

EXPOSE 9000

CMD ["php-fpm7", "--nodaemonize", "--fpm-config" , "/etc/php7/php-fpm.conf"]
