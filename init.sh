#!/usr/bin/env bash

. ./.env
workdir=$(cd `dirname $0`; pwd)

cd back
echo "Clone taiga back..."
git clone https://github.com/taigaio/taiga-back.git src
echo "Clone taiga front..."
cd ../front
git clone https://github.com/taigaio/taiga-front-dist.git src
echo "Clone taiga events..."
cd ../event
git clone https://github.com/taigaio/taiga-events.git src

# create back config
back_config=${workdir}/back/local.py
echo "Create back config file: ${back_config}"
cat > ${back_config} << EOF
# -*- coding: utf-8 -*-
# Copyright (C) 2014-2017 Andrey Antukh <niwi@niwi.nz>
# Copyright (C) 2014-2017 Jesús Espino <jespinog@gmail.com>
# Copyright (C) 2014-2017 David Barragán <bameda@dbarragan.com>
# Copyright (C) 2014-2017 Alejandro Alonso <alejandro.alonso@kaleidos.net>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from .development import *
import os

env_arr = os.environ

DEBUG = False
PUBLIC_REGISTER_ENABLED = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': env_arr['POSTGRES_DB'],
        'USER': env_arr['POSTGRES_USER'],
        'PASSWORD': env_arr['POSTGRES_PASSWORD'],
        'HOST': 'taiga-sql',
        'PORT': '5432'
    }
}

MEDIA_URL = "http://"+ env_arr['APP_DOMAIN'] +"/media/"
STATIC_URL = "http://"+ env_arr['APP_DOMAIN'] +"/static/"
SITES["front"]["scheme"] = "http"
SITES["front"]["domain"] = env_arr['APP_DOMAIN']

SECRET_KEY = env_arr['EVENT_SECRET_KEY']

EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://"+ env_arr['RABBITMQ_DEFAULT_USER'] +":"+ env_arr['RABBITMQ_DEFAULT_PASS'] +"@taiga-rabbitmq:5672/"+env_arr['RABBITMQ_DEFAULT_VHOST']}
EOF

# create front config
front_cofig=${workdir}/front/src/dist/conf.json
echo "Create front config file: ${front_cofig}"
cat > ${front_cofig} << EOF
{
    "api": "http://${APP_DOMAIN}/api/v1/",
    "eventsUrl": "ws://${APP_DOMAIN}/events",
    "eventsMaxMissedHeartbeats": 5,
    "eventsHeartbeatIntervalTime": 60000,
    "eventsReconnectTryInterval": 10000,
    "debug": true,
    "debugInfo": false,
    "defaultLanguage": "zh-hans",
    "themes": ["taiga"],
    "defaultTheme": "taiga",
    "publicRegisterEnabled": true,
    "feedbackEnabled": true,
    "supportUrl": "https://tree.taiga.io/support/",
    "privacyPolicyUrl": null,
    "termsOfServiceUrl": null,
    "GDPRUrl": null,
    "maxUploadFileSize": null,
    "contribPlugins": [],
    "tribeHost": null,
    "importers": [],
    "gravatar": false,
    "rtlLanguages": ["fa"]
}
EOF

# create event config
event_cofig=${workdir}/event/config.json
echo "Create event config file: ${event_cofig}"
cat > ${event_cofig} << EOF
{
    "url": "amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@taiga-rabbitmq:5672/${RABBITMQ_DEFAULT_VHOST}",
    "secret": "${EVENT_SECRET_KEY}",
    "webSocketServer": {
        "port": 8888
    }
}
EOF

# create nginx config
nginx_cofig=${workdir}/nginx/conf.d/app.conf
echo "Create nginx config file: ${nginx_cofig}"
cat > ${nginx_cofig} << EOF
server {
    listen 80;
    server_name _;

    large_client_header_buffers 4 32k;
    client_max_body_size 50M;
    charset utf-8;

    # Frontend
    location / {
        root /www/front/src/dist/;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend
    location /api {
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://taiga-back:8000/api;
        proxy_redirect off;
    }

    # Admin access (/admin/)
    location /admin {
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://taiga-back:8000\$request_uri;
        proxy_redirect off;
    }

    # Static files
    location /static {
        alias /www/back/src/static;
    }

    # Media files
    location /media {
        alias /www/back/src/media;
    }

    # Events
    location /events {
        proxy_pass http://taiga-event:8888/events;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
	}
}
EOF

docker-compose build
docker-compose run taiga-back ./init.sh
docker-compose up -d