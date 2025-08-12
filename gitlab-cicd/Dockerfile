FROM ubuntu:22.04

LABEL maintainer="POC2 Team"
LABEL description="GitLab CI/CD Pipeline Container with NetBox and n8n Integration"
LABEL version="1.0.0"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    jq \
    vim \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    # Network tools
    net-tools \
    iputils-ping \
    telnet \
    openssh-client \
    sshpass \
    # Development tools
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Database clients
    postgresql-client \
    redis-tools \
    # Other utilities
    zip \
    rsync \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Install GitLab Runner
RUN curl -L --output /usr/local/bin/gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64" \
    && chmod +x /usr/local/bin/gitlab-runner \
    && useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash \
    && usermod -aG docker gitlab-runner

# Install Node.js and npm (for n8n CLI and workflows)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install n8n CLI globally
RUN npm install -g n8n

# Install Ansible and network collections
RUN pip3 install --upgrade pip \
    && pip3 install \
        ansible \
        ansible-core \
        netaddr \
        jinja2 \
        paramiko \
        requests \
        pyyaml \
        pynetbox \
        napalm \
        nornir \
        nornir-netbox \
        nornir-napalm \
        nornir-utils

# Install Ansible Galaxy collections for network automation
RUN ansible-galaxy collection install \
    cisco.ios \
    cisco.nxos \
    cisco.iosxr \
    juniper.device \
    arista.eos \
    vyos.vyos \
    ansible.netcommon \
    community.network \
    netbox.netbox

# Install Terraform (for infrastructure automation)
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl for Kubernetes deployments
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm for Kubernetes package management
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y helm \
    && rm -rf /var/lib/apt/lists/*

# Create application directories
RUN mkdir -p /app/{scripts,configs,playbooks,workflows,templates} \
    && mkdir -p /var/lib/gitlab-runner \
    && mkdir -p /etc/gitlab-runner

# Copy CI/CD pipeline scripts
COPY scripts/ /app/scripts/
COPY configs/ /app/configs/
COPY playbooks/ /app/playbooks/
COPY workflows/ /app/workflows/

# Set up Python virtual environment for pipeline tools
RUN python3 -m venv /app/venv \
    && . /app/venv/bin/activate \
    && pip install --upgrade pip \
    && pip install \
        pynetbox \
        requests \
        pydantic \
        rich \
        click \
        httpx \
        asyncio \
        aiohttp

# Install additional Python packages for NetBox integration
RUN . /app/venv/bin/activate \
    && pip install \
        django \
        django-extensions \
        netbox-api \
        netbox-secrets \
        netbox-topology-views

# Install additional tools for pipeline automation
RUN pip3 install \
    boto3 \
    azure-cli \
    google-cloud-sdk \
    slack-sdk \
    pagerduty

# Create gitlab-runner user and set permissions
RUN chown -R gitlab-runner:gitlab-runner /var/lib/gitlab-runner \
    && chown -R gitlab-runner:gitlab-runner /etc/gitlab-runner \
    && chown -R gitlab-runner:gitlab-runner /app

# Add gitlab-runner to sudoers for Docker operations
RUN echo "gitlab-runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set environment variables for tools
ENV PATH="/app/venv/bin:$PATH"
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_RETRY_FILES_ENABLED=False
ENV ANSIBLE_SSH_PIPELINING=True
ENV PYTHONPATH="/app:$PYTHONPATH"

# Expose GitLab Runner metrics port
EXPOSE 9252

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Switch to gitlab-runner user
USER gitlab-runner
WORKDIR /var/lib/gitlab-runner

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD gitlab-runner verify || exit 1

ENTRYPOINT ["/entrypoint.sh"]
