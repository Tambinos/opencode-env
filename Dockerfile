RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" > /root/.ssh/known_hosts && \
    chmod 644 /root/.ssh/known_hosts
