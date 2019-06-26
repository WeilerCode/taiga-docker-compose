FROM python:3.6-alpine as builder

EXPOSE 8000

WORKDIR /taiga-back/

COPY ./src/requirements.txt ./requirements.txt

RUN echo "http://mirrors.aliyun.com/alpine/v3.9/main" > /etc/apk/repositories; \
    echo "http://mirrors.aliyun.com/alpine/v3.9/community" >> /etc/apk/repositories \
    && apk update \
    && apk add --no-cache gcc libffi-dev musl-dev postgresql-dev libxml2-dev libxslt-dev jpeg-dev gettext \
    && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn \
    && pip install --no-cache-dir -r requirements.txt