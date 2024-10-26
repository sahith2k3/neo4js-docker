# Base image: ubuntu:22.04
FROM ubuntu:22.04

ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

ARG GITHUB_TOKEN

# Install Java 17
RUN apt-get update && \
    apt-get remove -y openjdk-21-* && \
    apt-get install -y openjdk-17-jdk && \
    apt-get clean

# Set JAVA_HOME and update PATH
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install Neo4j 5.5.0 and other dependencies
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y nano unzip neo4j=1:5.5.0 python3-pip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get update && apt-get install -y libc6

# Clone the GitHub repository
#git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/Fall-24-CSE511-Data-Processing-at-Scale/Project-1-asankra1.git /project && \

RUN apt-get update && \
    apt-get install -y git && \
    git clone https://github.com/sahith2k3/neo4js-docker.git /project && \
    cd /project && \
    wget --no-check-certificate https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet && \
    pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

# Configure Neo4j
RUN sed -i 's/#server.default_listen_address=0.0.0.0/dbms.default_listen_address=0.0.0.0/' /etc/neo4j/neo4j.conf && \
    sed -i 's/#server.default_advertised_address=localhost/dbms.default_advertised_address=localhost/' /etc/neo4j/neo4j.conf

RUN neo4j-admin dbms set-initial-password project1phase1


# Run the data loader script

RUN chmod +x project/data_loader.py
RUN neo4j start && \
    python3 data_loader.py && \
    neo4j stop

# Expose neo4j ports
EXPOSE 7474 7687

# Start neo4j service and show the logs on container run
# CMD ["/bin/bash"]
CMD ["/bin/bash", "-c", "neo4j start && tail -f /dev/null"]