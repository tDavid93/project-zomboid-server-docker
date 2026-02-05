###########################################################
# Dockerfile that builds a Project Zomboid Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="daniel.carrasco@electrosoftcloud.com"

ENV STEAMAPPID=380870
ENV STEAMAPP=pz
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
# Fix for a new installation problem in the Steamcmd client
ENV HOME="${HOMEDIR}"

# Receive the value from docker-compose as an ARG
ARG STEAMAPPBRANCH="unstable"
# Promote the ARG value to an ENV for runtime
ENV STEAMAPPBRANCH=$STEAMAPPBRANCH

# Install required packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  dos2unix \
  sqlite3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Generate locales to allow other languages in the PZ Server
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
  # Generate locale
  && locale-gen

# Ensure UTF-8 locale for workshop paths with non-ASCII characters
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Download the Project Zomboid dedicated server app using the steamcmd app
# Set the entry point file permissions
RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && chown -R "${USER}:${USER}" "${STEAMAPPDIR}" \
  && for i in 1 2 3; do \
       if [ -n "${STEAMAPPBRANCH}" ] && [ "${STEAMAPPBRANCH}" != "stable" ]; then \
         bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
           +login anonymous \
           +app_update "${STEAMAPPID}" -beta "${STEAMAPPBRANCH}" validate \
           +quit && break; \
       else \
         bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
           +login anonymous \
           +app_update "${STEAMAPPID}" validate \
           +quit && break; \
       fi; \
       echo "SteamCMD attempt $i failed, retrying in 5 seconds..."; \
       sleep 5; \
     done

# Copy the entry point file
COPY --chown=${USER}:${USER} scripts/entry.sh /server/scripts/entry.sh
RUN chmod 550 /server/scripts/entry.sh

# Copy searchfolder file
COPY --chown=${USER}:${USER} scripts/search_folder.sh /server/scripts/search_folder.sh
RUN chmod 550 /server/scripts/search_folder.sh

# Create required folders to keep their permissions on mount
RUN mkdir -p "${HOMEDIR}/Zomboid"

WORKDIR ${HOMEDIR}
# Expose ports
EXPOSE 16261-16262/udp \
  27015/tcp

ENTRYPOINT ["/server/scripts/entry.sh"]
