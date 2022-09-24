#!/bin/bash

#############################################################
#   Author: Krzysztof Kuberski                              #
#   Contact: xkrzysztof.kuberskix@gmail.com                 #
#   Github: https://github.com/DeviC3/django-auto-deploy    #
#############################################################



dbuser="dbuser"
dbname="project"
dbpassword="password"
venv="project"
myprojectdir=/home/"$venv"
domainName=$(hostname --ip-address)
secretkey=$(openssl rand -base64 32)

function basicCheck(){
printf "Stopping other webservers \n"
systemctl stop apache2
systemctl disable apache2

apt update
apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl virtualenv -y
}

function dbCreate(){

printf "Creating Postgres data for Django\n"

su - postgres -c psql << EOF
CREATE DATABASE $dbname;
CREATE USER $dbuser WITH PASSWORD '$dbpassword';
ALTER ROLE $dbuser SET client_encoding TO 'utf8';
ALTER ROLE $dbuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE $dbuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE $dbname TO $dbuser;
\q
EOF

}

function pythonOps(){

printf "Entering virtual env. and downloading modules \n"

pip3 install --upgrade pip
pip3 install virtualenv

mkdir -p "$myprojectdir"
cd "$myprojectdir" || exit
virtualenv --python=/usr/bin/python3 "$venv"
source "$myprojectdir"/"$venv"/bin/activate
pip install django gunicorn psycopg2-binary

django-admin startproject "$venv" "$myprojectdir"

cat << EOF >  "$myprojectdir"/"$venv"/settings.py
"""
Django settings for website project.

Generated by 'djangobuild.sh' using Django 3.2.13.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/3.2/ref/settings/
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/3.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = '$secretkey'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['$domainName']


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    '$venv',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '$venv.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = '$venv.wsgi.application'


# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': '$dbname',
        'USER': '$dbuser',
        'PASSWORD': '$dbpassword',
        'HOST': 'localhost',
        'PORT': '',
    }
}


# Password validation
# https://docs.djangoproject.com/en/3.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/3.2/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/3.2/howto/static-files/

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')

# Default primary key field type
# https://docs.djangoproject.com/en/3.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF

printf "settings.py file created by script"

"$myprojectdir"/manage.py makemigrations
"$myprojectdir"/manage.py migrate

"$myprojectdir"/manage.py createsuperuser

"$myprojectdir"/manage.py collectstatic
}

function systemdServices(){

printf "Creating systemd services - gunicorn.socket and gunicorn.service in /etc/systemd/system/ \n"

cat << EOF > /etc/systemd/system/gunicorn.socket
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
EOF


cat << EOF > /etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=$myprojectdir
ExecStart=$myprojectdir/$venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          $venv.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start gunicorn.socket
systemctl enable gunicorn.socket

systemctl restart gunicorn

}

function nginxOps(){

printf "Creating nginx files for domain\n"

cat << EOF > /etc/nginx/sites-available/"$venv"
server {
    listen 80;
    server_name $domainName;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root "$myprojectdir";
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/"$venv" /etc/nginx/sites-enabled
nginx -t
systemctl restart nginx

}

basicCheck
dbCreate
pythonOps
systemdServices
nginxOps

printf "\nProject created, check settings.py file and nginx files to edit the settings.\nDebugging is set to True!\n"
