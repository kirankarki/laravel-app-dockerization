#
# PHP Dependencies
#
FROM composer:1.9.0 as vendor

COPY database/ database/

COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

#
# Frontend
#
FROM node:10.16 as frontend

RUN mkdir -p /app/public

COPY package.json webpack.mix.js yarn.lock /app/
COPY resources/js /app/resources/js
COPY resources/sass /app/resources/sass

WORKDIR /app

RUN yarn install && yarn production


# 
# Application
#
FROM php:7.3.5-fpm

# Create non-root group & user
RUN groupadd -g 61000 docker \
    && useradd -g 61000 -l -m -s /bin/bash -u 61000 docker

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && apt-get autoremove -y \
    && apt-get clean

WORKDIR /app

RUN chown -R docker:docker /app && chmod 755 /app

# Copy files by setting ownership
COPY --chown=docker:docker . .

USER docker

COPY --from=vendor --chown=docker:docker /app/vendor/ /app/vendor/
COPY --from=frontend --chown=docker:docker /app/public/js/ /app/public/js/
COPY --from=frontend --chown=docker:docker /app/public/css/ /app/public/css/
COPY --from=frontend --chown=docker:docker /app/mix-manifest.json /app/html/mix-manifest.json

RUN php artisan key:generate

CMD php artisan serve --host=0.0.0.0 --port=8000