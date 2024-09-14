FROM rstudio/r-base:4.4.1-focal

# Combine RUN commands to reduce layers
RUN apt-get update && \
    apt-get install -y \
        software-properties-common \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        libudunits2-dev \
        libnode-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        gdal-bin \
        jq \
        librsvg2-2 \
        libpq-dev \
        libv8-dev \
        libsodium-dev \
        libsecret-1-dev \
        libsasl2-dev \
        odbc-postgresql \
        libxml2-dev \
        libglpk-dev && \
    add-apt-repository ppa:ubuntugis/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        proj-data \
        proj-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up R environment
RUN mkdir -p ~/.R && \
    echo "PROJ_LIBS=/usr/lib" >> ~/.R/Makevars && \
    echo "PROJ_CPPFLAGS=-I/usr/include" >> ~/.R/Makevars

ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

# Install R packages
RUN R -e "install.packages(c('renv', 'terra'), repos = c(CRAN = 'https://cloud.r-project.org'))"

COPY renv.lock /renv.lock
RUN R -e 'renv::restore()'

# Copy application files
COPY www/ /app/www
COPY app.R utils.R /app/

# Set up the working directory and expose port
WORKDIR /app
EXPOSE 3838

# Run the application
CMD ["Rscript", "app.R"]