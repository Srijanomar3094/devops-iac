from prefect import flow, task

@task
def hello_task():
    print("Hello from Prefect!")
    return "Hello"

@task
def process_task(input_text: str):
    print(f"Processing: {input_text}")
    return f"Processed: {input_text}"

@flow(name="example-flow")
def example_flow():
    result = hello_task()
    final_result = process_task(result)
    print(f"Flow completed with result: {final_result}")
    return final_result

if __name__ == "__main__":
    example_flow()
