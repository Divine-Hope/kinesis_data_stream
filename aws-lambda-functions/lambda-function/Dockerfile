FROM public.ecr.aws/lambda/python:3.11

COPY requirements.txt  ${LAMBDA_TASK_ROOT}
RUN  pip3 install -r requirements.txt

COPY kinesis_processor.py ${LAMBDA_TASK_ROOT}

CMD [ "kinesis_processor.lambda_handler" ]