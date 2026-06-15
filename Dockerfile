# 1. 기반 이미지 설정
FROM rocker/tidyverse:4.4.0

# 2. 시스템 의존성 설치 (ImageMagick 포함)
USER root
RUN apt-get update && apt-get install -y \
    wget \
    git \
    imagemagick \
    libmagick++-dev \
    libzmq3-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Miniconda 설치
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 4. Conda 환경 생성 + Python 패키지 설치
#    분석용 패키지는 CI와 동일한 .github/python-packages.txt를 재사용하고,
#    Binder가 띄울 노트북 서버(jupyterlab/notebook)를 함께 넣는다.
ENV PATH=$CONDA_DIR/bin:$PATH
COPY .github/python-packages.txt /tmp/python-packages.txt
RUN conda create -n r-reticulate -c conda-forge --override-channels python=3.10 -y && \
    conda install -n r-reticulate -c conda-forge --override-channels -y \
    --file /tmp/python-packages.txt jupyterlab notebook

# r-reticulate 환경을 기본 PATH로 둬서 jupyter/python이 분석 패키지를 갖춘
# 이 환경을 가리키게 한다 (IRkernel::installspec과 Binder의 python3 커널 모두 이 환경 사용).
ENV PATH=/opt/conda/envs/r-reticulate/bin:$CONDA_DIR/bin:$PATH

# 5. R 패키지 설치 (CI와 동일한 .github/r-packages.txt 재사용 + IRkernel/remotes)
#    rocker 이미지에 이미 있는 패키지(tidyverse 등)는 건너뛴다.
COPY .github/r-packages.txt /tmp/r-packages.txt
RUN R -e "p <- readLines('/tmp/r-packages.txt'); p <- c(p[nzchar(p)], 'remotes', 'IRkernel'); need <- setdiff(p, rownames(installed.packages())); if (length(need)) install.packages(need)" && \
    R -e "IRkernel::installspec(user = FALSE)"

# 6. reticulate가 사용할 Python 경로 고정 (환경 변수)
ENV RETICULATE_PYTHON=/opt/conda/envs/r-reticulate/bin/python

# 7. Binder용 jovyan 유저 생성
ENV NB_USER=jovyan
ENV NB_UID=1000
RUN usermod -l ${NB_USER} rstudio && \
    usermod -d /home/${NB_USER} -m ${NB_USER} && \
    chown -R ${NB_USER} /opt/conda /home/${NB_USER}

# 노트북은 이 환경 이미지에 굽지 않는다. Binder가 gh-pages의 간단한 Dockerfile에서
# 이 이미지를 FROM 한 뒤 그때그때의 hw03.ipynb를 COPY 한다(환경/노트북 분리).
USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Binder가 기대하는 포트
EXPOSE 8888
