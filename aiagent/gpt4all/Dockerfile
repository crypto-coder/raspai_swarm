FROM ubuntu:22.04

LABEL maintainer="Chris Williams <chris@coincatcher.io>"

WORKDIR /aiagent
VOLUME /aiagent/models
EXPOSE 8080

ENV MODEL_BIN=/aiagent/models/openchat_3.5/openchat_3.5.Q4_K_M.gguf

RUN apt-get update && apt-get upgrade -y && apt-get -y install sudo git

RUN git clone --recurse-submodules https://github.com/nomic-ai/gpt4all.git /aiagent/gpt4all

# Build the GPT4All backend
COPY build-gpt4all-backend.sh /aiagent/build-gpt4all-backend.sh
RUN /aiagent/build-gpt4all-backend.sh

# Build the GPT4All API
COPY build-gpt4all-api.sh /aiagent/build-gpt4all-api.sh
RUN /aiagent/build-gpt4all-api.sh

# Install Uvicorn
RUN pip install --no-cache-dir --upgrade 'uvicorn[standard]'

# Start the API
ENV HOST=0.0.0.0
ENV PORT=8080
ENV LOG_LEVEL=info
ENV MODELS_PATH=/aiagent/models

COPY start-reload_gpt4all-api.sh /aiagent/start-reload_gpt4all-api.sh
ENTRYPOINT [ "/aiagent/start-reload_gpt4all-api.sh" ]



#COPY requirements.txt /tmp/requirements.txt
#RUN pip install --no-cache-dir -r /tmp/requirements.txt

#COPY ./start.sh /start.sh
#RUN chmod +x /start.sh

#COPY ./gunicorn_conf.py /gunicorn_conf.py

#COPY ./start-reload.sh /start-reload.sh
#RUN chmod +x /start-reload.sh

#COPY ./app /app
#WORKDIR /app/

#ENV PYTHONPATH=/app

#EXPOSE 80

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Gunicorn with Uvicorn
#CMD ["/start.sh"]


#FROM python:3.9

#WORKDIR /code

# Install Uvicorn
#COPY ./requirements.txt /code/requirements.txt

#RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

#COPY ./app /code/app

#CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]