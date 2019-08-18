FROM php:7.3.5-fpm

# Create non-root group & user
RUN groupadd -g 61000 docker \
    && useradd -g 61000 -l -m -s /bin/bash -u 61000 docker

WORKDIR /app

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get install -yq nodejs build-essential

# Copy files by setting ownership
COPY --chown=docker:docker ./ ./

USER docker

RUN composer install \
    && npm install \
    && npm run dev

CMD php artisan serve --host=0.0.0.0 --port=8000