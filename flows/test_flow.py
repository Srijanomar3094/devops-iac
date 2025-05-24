from prefect import flow, task

@task
def say_hello():
    return "Srijan's worker running"

@flow(name="test-flow")
def test_flow():
    message = say_hello()
    print(message)
    return message

if __name__ == "__main__":
    test_flow() 