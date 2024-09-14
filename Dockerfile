FROM  rocker/geospatial:4.4.1


RUN apt-get update &&  apt-get install --no-install-recommends -y jq librsvg2-2 libssl-dev libv8-dev  libsodium-dev libsecret-1-dev libcurl4-openssl-dev libsasl2-dev libxml2-dev libpq-dev libglpk-dev

ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

RUN R -e "install.packages(c('renv'), repos = c(CRAN = 'https://cloud.r-project.org'))"


COPY renv.lock /renv.lock

RUN R -e 'renv::restore()'

#Copy assets and static files (css, images, js...)
COPY www/ /app/www

#Copy script
COPY app.R /app
COPY utils.R /app

EXPOSE 3838

#Setting workspace directory to /app
WORKDIR /app


CMD ["Rscript", "app.R"] 