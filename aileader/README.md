## Overview

The AI Leader is based on [Autogen](https://github.com/microsoft/autogen) and it is run on a laptop / desktop development environment.  This allows us to host a `GroupChat` with a larger context window, and leverage faster hardware for coordinating the individual AI Agents.  Autogen, by default, will do quite a bit of 'self-talk' as it makes decisions about which AI Agents to engage, and even when it does engage other AI Agents, it will likely hit timeouts or content length limits.  We consider the AI Leader as the main focus for this repo and futher development.


## Running a test

1. Download an LLM to a local folder

    We are using `openchat_3.5` as the LLM for the AI Leader.  You will need to download this model and place it in the `models` subfolder.  The path for `openchat_3.5` would be the following:
    <br/>
    > ../models/openchat_3.5/openchat_3.5.Q4_K_M.gguf

    Make sure you also include the `config.json` and `README.md` files for this model.
    <br/>

2. Start a local LLM in docker, with a medium-sized context window

    ```
    docker run -it --name localllm -d -v ../models:/app/models -e n_threads=6 -e n_ctx=4096 -e MODEL=/app/models/openchat_3.5/openchat_3.5.Q4_K_M.gguf -p 9080:8080 registry.cc.local/coincatcher/aiagent-llama:latest
    ```

2. Start the `main.py` script

    This script assumes that a Local LLM is started on `localhost` and that it will be talking to 4 remote AI Agents.  You can modify this script to suite you test, including modifying the prompt.  Once executed, you should watch the local LLm and the LLM's running on the Raspberry Pis to see how they are operating.  Small tasks that require multiple skillsets (such as building and testing coded solutions), will best illustrate how this swarm of agents works together.