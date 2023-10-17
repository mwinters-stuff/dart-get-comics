FROM ubuntu

COPY get-comics-x86-64 /usr/local/bin/get-comics

CMD [ "/usr/local/bin/get-comics", "--config","/config/comics-config.yaml" ]

