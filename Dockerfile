FROM debian:jessie-backports

RUN apt-get update \
	&& apt-get install -y \
		curl \
		docker.io \
		linux-perf-4.4 \
		linux-perf-4.9

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh \
	&& bash nodesource_setup.sh \
	&& apt-get install nodejs

RUN npm install -g 0x@3

WORKDIR /app

ENTRYPOINT ["/app/analyzer.sh"]

COPY ./lib/ /app/

