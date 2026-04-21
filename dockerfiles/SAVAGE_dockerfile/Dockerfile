FROM ubuntu:22.04

LABEL version="1.0.1"

SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && apt-get install -y --no-install-recommends \
wget bzip2 ca-certificates curl git procps \
&& rm -rf /var/lib/apt/lists/*

ENV MAMBA_ROOT_PREFIX=/opt/conda 

ENV PATH=/opt/conda/bin:$PATH

RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba \
&& mv bin/micromamba /usr/local/bin/micromamba \
&& chmod +x /usr/local/bin/micromamba

COPY environment.yml /tmp/environment.yml

RUN micromamba create -y -n base -f /tmp/environment.yml && micromamba clean --all --yes

ENV PATH=/opt/conda/envs/base/bin:$PATH

CMD ["/bin/bash"]