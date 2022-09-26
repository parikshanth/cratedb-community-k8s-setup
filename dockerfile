FROM centos:7 AS builder

# Git install
RUN yum install -y git

RUN yum install -y yum-utils deltarpm \
    && yum makecache \
    && yum upgrade -y \
    && yum install -y python3 openssl \
    && pip3 install --upgrade pip \
    && yum clean all \
    && rm -rf /var/cache/yum

# JDK and JVM install
RUN yum install -y java-11-openjdk-headless java-11-openjdk-devel 
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.16.1.1-1.el7_9.x86_64
ENV PATH=$PATH:\$JAVA_HOME/bin


WORKDIR /tmp
RUN git clone https://github.com/crate/crate.git
WORKDIR /tmp/crate
RUN git submodule update --init
RUN git checkout 4.8
RUN ./gradlew distTar



FROM centos:7

RUN yum install -y java-11-openjdk-headless java-11-openjdk-devel 
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.16.1.1-1.el7_9.x86_64
ENV PATH=$PATH:\$JAVA_HOME/bin

RUN yum install -y yum-utils deltarpm \
    && yum makecache \
    && yum upgrade -y \
    && yum install -y python3 openssl \
    && pip3 install --upgrade pip \
    && yum clean all \
    && rm -rf /var/cache/yum

# Install CrateDB

COPY --from=builder /tmp/crate/app/build/distributions/crate-4.8.5-SNAPSHOT-a8d3d9d.tar.gz .


RUN groupadd crate \
    && useradd -u 1000 -g crate -d /crate crate \
    && export PLATFORM="$( \
        case $(uname --m) in \
            x86_64)  echo x64_linux ;; \
            aarch64) echo aarch64_linux ;; \
        esac)" \
    && tar -xf crate-4.8.5-SNAPSHOT-a8d3d9d.tar.gz -C /crate --strip-components=1 \
    && rm crate-4.8.5-SNAPSHOT-a8d3d9d.tar.gz


COPY --chown=1000:0 crate.yml /crate/config/crate.yml
COPY --chown=1000:0 log4j2.properties /crate/config/log4j2.properties


# Install crash
RUN curl -fSL -O https://cdn.crate.io/downloads/releases/crash_standalone_0.28.0 \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crash_standalone_0.28.0.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB \
    && gpg --batch --verify crash_standalone_0.28.0.asc crash_standalone_0.28.0 \
    && rm -rf "$GNUPGHOME" crash_standalone_0.28.0.asc \
    && mv crash_standalone_0.28.0 /usr/local/bin/crash \
    && chmod +x /usr/local/bin/crash

ENV PATH /crate/bin:$PATH
# Default heap size for Docker, can be overwritten by args
ENV CRATE_HEAP_SIZE 512M

RUN mkdir -p /data/data /data/log

VOLUME /data

WORKDIR /data

# http: 4200 tcp
# transport: 4300 tcp
# postgres protocol ports: 5432 tcp
EXPOSE 4200 4300 5432



COPY --chown=1000:0 docker-entrypoint.sh /
RUN  chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crate"]

