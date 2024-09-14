FROM rstudio/r-base:4.4.1-focal

# Ajouter le dépôt Ubuntugis pour obtenir des versions spécifiques de GDAL et PROJ
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntugis/ppa && \
    apt-get update

# Installer les dépendances système nécessaires, y compris libproj15 pour libproj.so.15
RUN apt-get install -y \
        libgdal-dev \
        libgeos-dev \
        libproj15 \
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

# Créer un lien symbolique si nécessaire (au cas où une autre version de PROJ serait présente)
RUN if [ ! -f /usr/lib/libproj.so.15 ] && [ -f /usr/lib/libproj.so.19 ]; then \
      ln -s /usr/lib/libproj.so.19 /usr/lib/libproj.so.15; \
    fi

# Définir les variables d'environnement pour GDAL et PROJ
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal
ENV PROJ_LIB=/usr/share/proj
ENV GDAL_DATA=/usr/share/gdal

# Installer les packages R de base et renv
RUN R -e "install.packages(c('renv','terra'), repos = 'https://cloud.r-project.org')"

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
