
# Use fix Node-red docker release
FROM nodered/node-red:5.0.9-24

# Switch to root user
USER root

# Set environment variables
ENV DKNR_USERNAME=admin \
	DKNR_PASSWORD=admin \
      DKNR_SECRET=dkdomotic \
      DKNR_REPOSITORY=https://github.com/dknr-domotic/dknr-domotic \
      NODE_RED_ENABLE_PROJECTS=true \
	TZ=Europe\Paris

# Image label
LABEL org.opencontainers.image.authors="Jean-Christian Paul Denis" \
      org.opencontainers.image.source="https://github.com/dknr-domotic/dknr-domotic" \
      org.opencontainers.image.title="DKNR Domotic" \
      org.opencontainers.image.description="Domotic web UI customized to my needs" \
      org.opencontainers.image.licenses="AGPL-3.0"

# Set system timezone
RUN echo "$TZ" > /etc/timezone

# Prepare Node-Red structure
RUN mkdir -p /data/projects/dknr-domotic

# Clone repository
RUN git clone ${DKNR_REPOSITORY} /data/projects/dknr-domotic

# Fix ownership
RUN chown -R node-red:node-red /data

# Switch to node-red user
USER node-red

# Set working diretory for container starting script
WORKDIR /data

# Add container starting script
ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
