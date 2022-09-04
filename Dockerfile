FROM python:latest

# pyenv installation
ENV HOME /root
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/bin:$PATH
RUN apt-get update -y && \
    apt-get install -y build-essential \
        libffi-dev \
        libssl-dev \
        zlib1g-dev \
        liblzma-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libopencv-dev \
        tk-dev \
        git &&\
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# pipenv installation
RUN pip install --upgrade pip &&\
    pip install pipenv &&\
    pipenv install

# workdir make
RUN mkdir /app
WORKDIR /app
EXPOSE 5000
ADD docker-entrypoint.sh /app/docker-entrypoint.sh

# Add files to container 
ADD ./src /app/src
ADD ./Pipfile /app/Pipfile
RUN mkdir /var/log/flask
ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
