FROM  rstudio/r-base:4.2.0-focal



RUN apt-get update

    

RUN apt-get update &&  apt-get install --no-install-recommends -y jq librsvg2-2 libpq-dev libssl-dev libv8-dev  libsodium-dev libcurl4-openssl-dev libsasl2-dev  odbc-postgresql gdal-bin libgdal-dev libxml2-dev libpq-dev libglpk-dev
RUN echo "[postgresql]\nDriver          = /usr/lib/x86_64-linux-gnu/odbc/psqlodbcw.so" >> /etc/odbcinst.ini

ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

ENV RENV_VERSION 1.0.7
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"


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

