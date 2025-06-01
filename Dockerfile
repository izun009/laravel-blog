FROM php:8.3-fpm

USER root

# Set working directory
WORKDIR /var/www

# Install system dependencies and PHP extension libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    vim \
    jpegoptim optipng pngquant gifsicle

ARG NODE_VERSION=20.18.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    corepack enable && \
    rm -rf /tmp/node-build-master

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl

# GD configuration must be done before installing
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create a non-root user
RUN groupadd -g 1000 www && \
    useradd -u 1000 -ms /bin/bash -g www www

# Copy project files with correct ownership
COPY --chown=www:www . /var/www

# Install Composer dependencies inside image
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Precompiling assets for production
RUN yarn install --immutable && \
    yarn build && \
    rm -rf node_modules

# Set correct permissions
RUN chmod -R 775 storage bootstrap/cache || true

# Switch to non-root user
USER www

# Expose port and run PHP-FPM
EXPOSE 9000
CMD ["php-fpm"]
