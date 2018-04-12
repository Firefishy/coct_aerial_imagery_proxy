FROM debian:sid

RUN apt-get update && apt-get install --no-install-recommends -y \
     gdal-bin \
     xmlstarlet \
     cgi-mapserver \
     spawn-fcgi \
     multiwatch \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV GDAL_CACHEMAX=1024

# ENV GDAL_HTTP_CONNECTTIMEOUT
# ENV GDAL_HTTP_TIMEOUT
# ENV GDAL_HTTP_MAX_RETRY
# ENV GDAL_HTTP_RETRY_DELAY=10
# ENV GDAL_HTTP_PROXY=cache:3128

ENV MS_MAPFILE="/app/ct-aerial.map"
ENV MS_MAPFILE_PATTERN="\.map$"
ENV MS_DEBUGLEVEL="0"
ENV MS_ERRORFILE="stderr"
ENV MS_ERRORFILE="stderr"

WORKDIR /app

COPY ct-aerial.map ./

RUN gdal_translate \
    "WMTS:https://citymaps.capetown.gov.za/agsext1/rest/services/Aerial_Photography_Cached/AP_2017_Jan/MapServer/WMTS/1.0.0/WMTSCapabilities.xml" \
    wmts.xml -of WMTS \
    && xmlstarlet ed -L \
    -s '//GDAL_WMTS/Cache' -t elem -n 'Path' -v '/gdalwmscache' \
    -s '//GDAL_WMTS/Cache' -t elem -n 'Depth' -v '2' \
    -s '//GDAL_WMTS/Cache' -t elem -n 'Extension' -v '.jpg' \
    -s '//GDAL_WMTS/Cache' -t elem -n 'Expires' -v '31536000' \
    -s '//GDAL_WMTS/Cache' -t elem -n 'MaxSize' -v '17179869184' \
    -s '//GDAL_WMTS' -t elem -n 'MaxConnections' -v '6' \
    -s '//GDAL_WMTS' -t elem -n 'Timeout' -v '30' \
    wmts.xml

RUN cat wmts.xml

VOLUME /gdalwmscache

EXPOSE 9000

CMD ["/usr/bin/spawn-fcgi", "-n", "-p", "9000", "-b", "1", "--", "/usr/bin/multiwatch", "-f", "4", "--signal=TERM", "--", "/usr/lib/cgi-bin/mapserv"]
