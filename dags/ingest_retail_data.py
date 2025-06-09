import os
from datetime import datetime
import zipfile
import pandas as pd

from airflow.decorators import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

DATA_URL = "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
LANDING_ZONE_PATH = "/opt/airflow/store"
S3_BUCKET_NAME = "demand-forecast-data-lake-74b009f5" 
S3_KEY = "raw/online_retail_II.csv" # The final path in S3
@dag(
    dag_id="data_ingestion_to_s3",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,  # This DAG is not scheduled, it runs manually
    catchup=False,
    tags=["data_ingestion"],
    doc_md="""
    This DAG downloads the Online Retail II dataset, processes it,
    and uploads the cleaned CSV to an S3 raw zone.
    """
)

def ingest_retail_data_dag():
    @task
    def download_and_unzip_data() -> str:
        """Downloads and unzips the dataset, returns the path to the excel file."""
        zip_file_path = os.path.join(LANDING_ZONE_PATH, "online_retail_II.zip")
        extracted_folder_path = os.path.join(LANDING_ZONE_PATH, "online_retail_II")

        os.makedirs(LANDING_ZONE_PATH, exist_ok=True)

        # Download the file
        os.system(f"curl -o {zip_file_path} {DATA_URL}")

        # Unzip the file
        with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
            zip_ref.extractall(extracted_folder_path)

        # Find the excel file
        for file in os.listdir(extracted_folder_path):
            if file.endswith(".xlsx"):
                return os.path.join(extracted_folder_path, file)
        raise FileNotFoundError("Excel file not found in the zip archive.")

    @task
    def convert_excel_to_csv_and_upload(excel_file_path: str):
        """Converts the Excel file to CSV and uploads it to S3."""
        # Read the excel file
        df = pd.read_excel(excel_file_path)

        # Convert to CSV format in memory
        csv_buffer = df.to_csv(index=False)
        
        # Upload to S3 using the S3Hook
        s3_hook = S3Hook(aws_conn_id="aws_default")
        s3_hook.load_string(
            string_data=csv_buffer,
            key=S3_KEY,
            bucket_name=S3_BUCKET_NAME,
            replace=True,
        )
        print(f"Successfully uploaded {S3_KEY} to bucket {S3_BUCKET_NAME}.")

    # Define the task dependencies
    excel_path = download_and_unzip_data()
    convert_excel_to_csv_and_upload(excel_path)

# Instantiate the DAG
ingest_retail_data_dag()