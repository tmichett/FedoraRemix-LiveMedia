# Fedora Remix LiveMedia builder — livemedia-creator (lorax), modeled on RemixBuilder/Containerfile.
# Build: ./build.sh   (reads FEDORA_VERSION from config.yml)
# Run:  ./Build_LiveMedia.sh

ARG FEDORA_VERSION=43
FROM fedora:${FEDORA_VERSION}

# osbuild-selinux: load .pp in entrypoint before anaconda/setfiles in chroot (same pattern as livecd RemixBuilder).
# lorax: livemedia-creator; pykickstart: ksflatten; anaconda: required for --no-virt (see pylorax livemedia.py)
# httpd/rsync: Prepare_Web_Files.py
RUN dnf install -y \
    python3-pyyaml \
    httpd \
    sshfs \
    rsync \
    lorax \
    pykickstart \
    anaconda \
    vim \
    git \
    python3 \
    systemd \
    glibc-langpack-en \
    osbuild-selinux \
    util-linux-script \
    && dnf clean all

RUN localedef -i en_US -f UTF-8 en_US.UTF-8 || true

RUN echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile.d/locale.sh && \
    echo 'export LANG=en_US.UTF-8' >> /etc/profile.d/locale.sh && \
    echo 'export LANGUAGE=en_US.UTF-8' >> /etc/profile.d/locale.sh

RUN echo 'exit_container() { systemctl poweroff; }' >> /root/.bashrc && \
    echo 'alias exit="exit_container"' >> /root/.bashrc && \
    echo 'if [ ! -f /tmp/entrypoint-completed ]; then' >> /root/.bashrc && \
    echo '  echo ""' >> /root/.bashrc && \
    echo '  echo "=========================================="' >> /root/.bashrc && \
    echo '  echo "LiveMedia entrypoint status:"' >> /root/.bashrc && \
    echo '  systemctl is-active livemedia-builder.service >/dev/null 2>&1 && echo "  Status: Running or completed"' >> /root/.bashrc && \
    echo '  systemctl is-failed livemedia-builder.service >/dev/null 2>&1 && echo "  Status: Failed - check logs"' >> /root/.bashrc && \
    echo '  echo ""' >> /root/.bashrc && \
    echo '  if [ -f /tmp/entrypoint.log ]; then' >> /root/.bashrc && \
    echo '    echo "Recent entrypoint output:"' >> /root/.bashrc && \
    echo '    tail -20 /tmp/entrypoint.log' >> /root/.bashrc && \
    echo '  fi' >> /root/.bashrc && \
    echo '  echo ""' >> /root/.bashrc && \
    echo '  echo "View full logs: journalctl -u livemedia-builder.service -n 100"' >> /root/.bashrc && \
    echo '  echo "Or: tail -f /tmp/entrypoint.log"' >> /root/.bashrc && \
    echo '  echo "Or re-run: /entrypoint.sh"' >> /root/.bashrc && \
    echo '  echo "=========================================="' >> /root/.bashrc && \
    echo '  echo ""' >> /root/.bashrc && \
    echo 'else' >> /root/.bashrc && \
    echo '  echo "Entrypoint has completed successfully."' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc && \
    echo 'echo "Type \"exit\" to shutdown the container"' >> /root/.bashrc

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY ssh_config /root/.ssh/config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN rm -f /etc/systemd/system/default.target && \
    ln -s /usr/lib/systemd/system/multi-user.target /etc/systemd/system/default.target

RUN ln -sf /dev/null /etc/systemd/system/console-getty.service

RUN echo '[Unit]' > /etc/systemd/system/livemedia-builder.service && \
    echo 'Description=Run Fedora Remix LiveMedia entrypoint' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'After=local-fs.target loop-devices.service systemd-journald.socket' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'Requires=local-fs.target loop-devices.service' >> /etc/systemd/system/livemedia-builder.service && \
    echo '' >> /etc/systemd/system/livemedia-builder.service && \
    echo '[Service]' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'ExecStart=/entrypoint.sh' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'RemainAfterExit=yes' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'PassEnvironment=REMIX_KICKSTART REMIX_INCLUDE_PXEBOOT' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'StandardOutput=journal+console' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'StandardError=journal+console' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'StandardInput=null' >> /etc/systemd/system/livemedia-builder.service && \
    echo '' >> /etc/systemd/system/livemedia-builder.service && \
    echo '[Install]' >> /etc/systemd/system/livemedia-builder.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/livemedia-builder.service

RUN mkdir -p /etc/systemd/system/multi-user.target.wants && \
    ln -s /etc/systemd/system/livemedia-builder.service /etc/systemd/system/multi-user.target.wants/livemedia-builder.service

RUN echo '[Unit]' > /etc/systemd/system/loop-devices.service && \
    echo 'Description=Create loop devices for livemedia-creator' >> /etc/systemd/system/loop-devices.service && \
    echo 'Before=livemedia-builder.service' >> /etc/systemd/system/loop-devices.service && \
    echo '' >> /etc/systemd/system/loop-devices.service && \
    echo '[Service]' >> /etc/systemd/system/loop-devices.service && \
    echo 'Type=oneshot' >> /etc/systemd/system/loop-devices.service && \
    echo 'ExecStart=/bin/bash -c "for i in {0..7}; do mknod -m 0660 /dev/loop$i b 7 $i 2>/dev/null || true; done"' >> /etc/systemd/system/loop-devices.service && \
    echo 'RemainAfterExit=yes' >> /etc/systemd/system/loop-devices.service && \
    echo '' >> /etc/systemd/system/loop-devices.service && \
    echo '[Install]' >> /etc/systemd/system/loop-devices.service && \
    echo 'WantedBy=multi-user.target' >> /etc/systemd/system/loop-devices.service && \
    mkdir -p /etc/systemd/system/multi-user.target.wants && \
    ln -s /etc/systemd/system/loop-devices.service /etc/systemd/system/multi-user.target.wants/loop-devices.service

WORKDIR /root/workspace

ENTRYPOINT ["/usr/sbin/init"]
