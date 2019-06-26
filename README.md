# tagai-docker-compose
tagai for docker-compose


### install

1. `git clone https://github.com/WeilerCode/taiga-docker-compose.git`
2. 修改.env配置
3. `./init.sh`

> 如果`APP_DOMAIN`填写的是直接使用IP则使用`IP:8081`格式,完成安装后直接访问http://ip:8081
> 如果`APP_DOMAIN`填写的是域名，则需要配置NGINX代理