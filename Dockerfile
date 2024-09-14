FROM rstudio/r-base:4.4.1-focal

# Ajout du dépôt Ubuntugis pour obtenir les dernières versions de GDAL et PROJ
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntugis/ppa && \
    apt-get update

# Installer les dépendances système nécessaires
RUN apt-get install -y \
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
        libglpk-dev \
        proj-data \
        proj-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Définir les variables d'environnement pour GDAL, PROJ et GEOS
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal
ENV PROJ_LIB=/usr/share/proj
ENV GDAL_DATA=/usr/share/gdal

# Installer les packages R de base et renv
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Copier le fichier renv.lock avant de restaurer les dépendances
COPY renv.lock /renv.lock
RUN R -e "renv::restore()"

# Copier les fichiers de l'application
COPY www/ /app/www
COPY app.R utils.R /app/

# Définir le répertoire de travail
WORKDIR /app

# Exposer le port pour Shiny (ou l'application web)
EXPOSE 3838

# Lancer l'application au démarrage du conteneur
CMD ["Rscript", "app.R"]
