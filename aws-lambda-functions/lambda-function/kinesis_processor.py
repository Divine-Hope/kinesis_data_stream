import base64
import json
import boto3
import pandas as pd
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel("INFO")

s3_resource = boto3.resource('s3')
s3_bucket_name = 'babbel-test-divine'


def lambda_handler(event, context):
    all_data = []

    for record in event['Records']:
        try:

            payload = base64.b64decode(record["kinesis"]["data"])
            data = json.loads(payload)
            all_data.append(data)
            logger.info("successfully decoded data")
        except Exception as e:
            logger.error(f"Error decoding record: {e}")
            continue

    if not all_data:
        logger.info("No data to process.")
        return {
            'statusCode': 200,
            'body': json.dumps('No data to process.')
        }

    try:
        df = pd.DataFrame(all_data)

        df['created_at'] = pd.to_datetime(df['created_at'], unit='s')
        df['created_datetime'] = df['created_at'].apply(lambda x: x.isoformat())

        if 'event_name' in df.columns:
            event_parts = df['event_name'].str.split(':', expand=True)
            df['event_type'], df['event_subtype'] = event_parts[0], event_parts[1]

        df['year'] = df['created_at'].dt.year
        df['month'] = df['created_at'].dt.month
        df['day'] = df['created_at'].dt.day

        now = datetime.now()
        file_name = f"{now.strftime('%Y%m%d%H%M%S')}.parquet"
        file_path = f"events/year={now.year}/month={now.month}/day={now.day}/{file_name}"
        df.to_parquet(f"/tmp/{file_name}", index=False, engine='fastparquet')

        logger.info("successfully converted to parquet")
    except Exception as e:
        logger.error(f"Error processing DataFrame: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing DataFrame.')
        }

    try:
        s3_resource.Bucket(s3_bucket_name).upload_file(f"/tmp/{file_name}", file_path)
        logger.info("successfully uploaded to s3")
    except Exception as e:
        logger.error(f"Error uploading file to S3: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error uploading file to S3.')
        }

    return {
        'statusCode': 200,
        'body': json.dumps('Success!')
    }
