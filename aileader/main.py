import autogen
import asyncio



#AGENT01-DEFAULT_MODEL=openchat_3.5
#AGENT02-DEFAULT_MODEL=dolphin-2.1-mistral-7b
#AGENT03-DEFAULT_MODEL=orca-2-7b
#AGENT04-DEFAULT_MODEL=neural-chat-7b-v3-1



llm_comfig_openchat={
    "model": "openchat_3.5",
    "config_list": [
        {
            "model": "openchat_3.5",
            "base_url": "http://aiagent01.cc.local/v1",
            "api_key": "Null"
        }
    ]
}
llm_comfig_dolphin={
    "model": "dolphin-2.1-mistral-7b",
    "config_list": [
        {
            "model": "dolphin-2.1-mistral-7b",
            "base_url": "http://aiagent02.cc.local/v1",
            "api_key": "Null"
        }
    ]
}
llm_comfig_orca={
    "model": "orca-2-7b",
    "config_list": [
        {
            "model": "orca-2-7b",
            "base_url": "http://aiagent03.cc.local/v1",
            "api_key": "Null"
        }
    ]
}
llm_comfig_neuralchat={
    "model": "neural-chat-7b-v3-1",
    "config_list": [
        {
            "model": "neural-chat-7b-v3-1",
            "base_url": "http://aiagent04.cc.local/v1",
            "api_key": "Null"
        }
    ]
}
llm_comfig_local={
    "model": "openchat_3.5",
    "config_list": [
        {
            "model": "openchat_3.5",
            "base_url": "http://127.0.0.1:9080/v1",
            "api_key": "Null"
        }
    ]
}



assistant = autogen.AssistantAgent(
    name="Assistant",
    llm_config=llm_comfig_openchat
)
coder = autogen.AssistantAgent(
    name="Coder",
    llm_config=llm_comfig_orca
)
user_proxy = autogen.UserProxyAgent(
    name="user_proxy",
    human_input_mode="TERMINATE",
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda x: x.get("content", "").rstrip().endswith("TERMINATE"),
    code_execution_config={"work_dir": "web"},
    llm_config=llm_comfig_dolphin,
    system_message="""Reply TERMINATE if the task has been solved at full satisfaction. 
    Otherwise, reply CONTINUE, or the reason why the task is not solved yet."""
)



task="""
How would I build a Shopify extension that allows me to attach a promo code to the checkout process?
"""



groupchat = autogen.GroupChat(agents=[user_proxy, coder, assistant], messages=[], max_round=12)
manager = autogen.GroupChatManager(groupchat=groupchat, llm_config=llm_comfig_local)
asyncio.run(user_proxy.a_initiate_chat(manager, message=task))