from airflow import DAG

from airflow.providers.http.sensors.http import HttpSensor
from airflow.sensors.filesystem import FileSensor

from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

from airflow.providers.apache.hive.operators.hive import HiveOperator
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.operators.email import EmailOperator
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator

from datetime import datetime, timedelta
import csv
import requests
import json
import os

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "rajesh920352@gmail.com",
    "retries": 1,
    "retry_delay": timedelta(minutes=5)
}


def delete_file_if_exists(file_path):
    if os.path.exists(file_path):
        # Delete the file
        os.remove(file_path)


def download_rates():
    BASE_URL = "https://gist.github.com/marclamberti/f45f872dea4dfd3eaa015a4a1af4b39b/raw/"
    ENDPOINTS = {
        'USD': 'api_forex_exchange_usd.json',
        'EUR': 'api_forex_exchange_eur.json'
    }

    OUTPUT_PATH = "/opt/airflow/temp"
    delete_file_if_exists(f"{OUTPUT_PATH}/forex_rates.json")
    with open(f"{OUTPUT_PATH}/forex_currencies.csv") as forex_currencies:
        reader = csv.DictReader(forex_currencies, delimiter=';')
        for idx, row in enumerate(reader):
            base = row['base']
            with_pairs = row['with_pairs'].split(' ')
            indata = requests.get(f"{BASE_URL}{ENDPOINTS[base]}").json()
            outdata = {'base': base, 'rates': {}, 'last_update': indata['date']}
            for pair in with_pairs:
                outdata['rates'][pair] = indata['rates'][pair]
            with open(f"{OUTPUT_PATH}/forex_rates.json", 'a') as outfile:
                json.dump(outdata, outfile)
                outfile.write('\n')


def _get_message() -> str:
    return "Hi from forex_data_pipeline"


with DAG(dag_id="test_forex_data_pipeline",
         start_date=datetime(2021, 1, 1),
         schedule_interval="@daily",
         default_args=default_args,
         catchup=False
         ) as dag:
    is_forex_rates_available = HttpSensor(
        task_id="is_forex_rates_available",
        http_conn_id="forex_api",
        endpoint="marclamberti/f45f872dea4dfd3eaa015a4a1af4b39b",
        response_check=lambda response: "rates" in response.text,
        poke_interval=5,
        timeout=20
    )

    is_forex_currencies_file_available = FileSensor(
        task_id="is_forex_currencies_file_available",
        fs_conn_id="forex_path",
        filepath="forex_currencies.csv",
        poke_interval=5,
        timeout=20
    )

    # Parsing forex_pairs.csv and downloading the files
    downloading_rates = PythonOperator(
        task_id="downloading_rates",
        python_callable=download_rates
    )

    # Saving forex_rates.json in HDFS
    saving_rates = BashOperator(
        task_id="saving_rates",
        bash_command="""
            hdfs dfs -mkdir -p /user/airflow/forex && \
            hdfs dfs -put -f $AIRFLOW_HOME/temp/forex_rates.json /user/airflow/forex/
            """
    )

    # Creating a hive table named forex_rates
    creating_forex_rates_table = HiveOperator(
        task_id="creating_forex_rates_table",
        hive_cli_conn_id="hive_conn",
        hql="""
            CREATE EXTERNAL TABLE IF NOT EXISTS forex_rates(
                base STRING,
                last_update DATE,
                eur DOUBLE,
                usd DOUBLE,
                nzd DOUBLE,
                gbp DOUBLE,
                jpy DOUBLE,
                cad DOUBLE
                )
            ROW FORMAT DELIMITED
            FIELDS TERMINATED BY ','
            STORED AS TEXTFILE
        """
    )

    # Running Spark Job to process the data
    forex_processing = SparkSubmitOperator(
        task_id="forex_processing",
        conn_id="spark_conn",
        application="/opt/airflow/temp/forex_processing.py",
        verbose=False
    )

    # Sending a notification by email
    # https://stackoverflow.com/questions/51829200/how-to-set-up-airflow-send-email
    sending_email_notification = EmailOperator(
        task_id="sending_email",
        to="rajesh920352@gmail.com",
        subject="forex_data_pipeline",
        html_content="""
                   <h3>forex_data_pipeline succeeded</h3>
               """
    )

    # Sending a notification by Slack message
    # TODO: Improvements - add on_failure for tasks
    # https://medium.com/datareply/integrating-slack-alerts-in-airflow-c9dcd155105
    sending_slack_notification = SlackWebhookOperator(
        task_id="send_slack_notification",
        http_conn_id="slack_conn",
        message=_get_message(),
        channel="#monitoring"
    )

    is_forex_rates_available >> is_forex_currencies_file_available >> downloading_rates >> saving_rates
    saving_rates >> creating_forex_rates_table >> forex_processing
    forex_processing >> sending_email_notification >> sending_slack_notification
