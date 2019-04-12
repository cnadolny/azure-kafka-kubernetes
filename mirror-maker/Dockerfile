FROM confluentinc/cp-kafka:5.1.2

RUN mkdir -p /usr/src/mirror-maker/
ADD ./run.sh /usr/src/mirror-maker/

WORKDIR /usr/src/mirror-maker

ENTRYPOINT ["/usr/src/mirror-maker/run.sh"]