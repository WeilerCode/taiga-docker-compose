#!/usr/bin/env bash

cd back
git clone https://github.com/taigaio/taiga-back.git src
cd ../front
git clone https://github.com/taigaio/taiga-front-dist.git src
cd ../event
git clone https://github.com/taigaio/taiga-events.git src
