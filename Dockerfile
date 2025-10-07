FROM femtopixel/google-chrome-headless
# RUN apt-get update && apt-get -y install tzdata && apt-get clean

COPY get-comics-x86-64 /usr/local/bin/get-comics
USER root

CMD [ "/usr/local/bin/get-comics", "--config","/config/comics-config.yaml" ]

