FROM debian:stretch 

ARG BUILD_DATE
ARG VERSION

LABEL org.label-schema.name="Domoticz" \
      org.label-schema.description="Domoticz app running over Debian, with OpenZWave and Python-Miio (Xiaomi)" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$VERSION

RUN \
   echo "---- Install Packages ----" && \
      apt-get update && apt-get install -y --no-install-recommends --fix-missing \
          git \
          libssl1.0.2 libssl-dev libffi-dev \
          build-essential cmake \
          libboost-dev \
          libboost-thread1.62.0 libboost-thread-dev \
          libboost-system1.62.0 libboost-system-dev \
          libboost-date-time1.62.0 libboost-date-time-dev \
          libsqlite3-0 libsqlite3-dev \
          curl libcurl3 libcurl4-openssl-dev \
          libusb-0.1-4 libusb-dev \
          zlib1g-dev \
          libudev-dev \
          linux-headers-amd64 \
          python3.5 python3-dev \
          ca-certificates && \
   echo "---- Build Open ZWave ----" && \
      git clone --depth 2 https://github.com/OpenZWave/open-zwave.git /src/open-zwave-read-only && \
      cd /src/open-zwave-read-only && \
      make && \
   echo "---- Build Domoticz ----" && \
      git clone --depth 2 https://github.com/domoticz/domoticz.git /src/domoticz && \
      cd /src/domoticz && \
      # Domoticz needs git history to compute version
      git fetch --unshallow && \
      cmake -DCMAKE_BUILD_TYPE=Release . && \
      make && \
   echo "---- Install Python Pip ----" && \
      curl https://bootstrap.pypa.io/get-pip.py -o /src/get-pip.py && \
      cd /src && \
      python3 get-pip.py && \
   echo "---- Install Miio for Xiaomi Devices ----" && \
      pip3 install python-miio && \
   echo "---- Clean Packages & Directories ----" && \
      apt-get remove -y \
         # Do not remove python3-dev as Domoticz's PluginSystem needs it !!
         git cmake build-essential \
         linux-headers-amd64 \
         libboost-dev libboost-thread-dev libboost-system-dev \
         libssl-dev libsqlite3-dev libcurl4-openssl-dev libusb-dev zlib1g-dev libudev-dev && \
      apt-get autoremove -y && \ 
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* && \
      rm -rf /src/domoticz/.git && \
      rm -rf /src/open-zwave-read-only/.git && \
      rm -f /src/get-pip.py

VOLUME /config
VOLUME /src/domoticz/www/images/floorplans
VOLUME /src/domoticz/plugins

EXPOSE 3280 
EXPOSE 3240

HEALTHCHECK --interval=5m --timeout=3s \
   CMD curl -f http://localhost:3280/ || exit 1

ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db"]
CMD ["-www", "3280", "-sslwww", "3240", "-sslcert", "/config/keys/server_cert.pem", "-syslog"]
