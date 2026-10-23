RUN apt-get update && apt-get install -y openssh-client git && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y openssh-client git socat && rm -rf /var/lib/apt/lists/*

