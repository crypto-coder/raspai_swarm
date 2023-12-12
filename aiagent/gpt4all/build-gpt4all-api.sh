#!/bin/bash

# MAKE SURE EVERYTHING IS UPDATED BEFORE YOU START
if [ "$USER" = "root" ]; then
    apt-get upgrade -y
else
    sudo apt-get upgrade -y
fi

# Move to the working directory
if [ "$HOME" = "" ]; then
    mkdir -p /aiagent
    cd /aiagent
else
    mkdir -p $HOME/dev/aiagent
    cd $HOME/dev/aiagent
fi

# Make sure we have a clone of the GPT4All repo in a predictable place
if [ ! -d "./gpt4all" ]; then
    git clone --recurse-submodules https://github.com/nomic-ai/gpt4all.git gpt4all
fi

# Modify the API to use environment variables
cd gpt4all/gpt4all-api/gpt4all_api/app/api_v1
sed -i '1 s/^/import os\n/' settings.py
sed -i "s@'ggml-mpt-7b-chat.bin'@os.environ.get(\"MODEL_BIN\", \"ggml-mpt-7b-chat.bin\")@" settings.py
sed -i "s@'\/models'@os.environ.get(\"MODELS_PATH\", \"\/aiagent\/models\")@" settings.py

# Build the API
cd ../..
pip install --upgrade pip
pip install -r ./requirements.txt
rm -Rf /root/.cache
rm -Rf /tmp/pip-install*



# Put first so anytime this file changes other cached layers are invalidated.
#COPY gpt4all_api/requirements.txt /requirements.txt

#RUN pip install --upgrade pip

# Run various pip install commands with ssh keys from host machine.
#RUN --mount=type=ssh pip install -r /requirements.txt && \
#  rm -Rf /root/.cache && rm -Rf /tmp/pip-install*

# Finally, copy app and client.
#COPY gpt4all_api/app /app

#RUN mkdir -p /models

# Include the following line to bake a model into the image and not have to download it on API start.
#RUN wget -q --show-progress=off https://gpt4all.io/models/${MODEL_BIN} -P /models \
#  && md5sum /models/${MODEL_BIN}