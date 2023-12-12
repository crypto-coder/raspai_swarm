import time
from functools import wraps
from gpt4all import GPT4All

def timer(func):
    """A decorator that prints the execution time of the function it decorates."""

    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"{func.__name__} ran in: {end_time - start_time} sec")
        return result

    return wrapper

@timer
def ask(prompt):
    model = GPT4All("orca-mini-3b-gguf2-q4_0.gguf")
    output = model.generate(prompt, max_tokens=512)
    return output

if __name__ == "__main__":
    answer = ask("The capital of France is ")
    print(answer)