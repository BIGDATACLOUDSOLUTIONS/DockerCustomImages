#Documentation: https://airflow.apache.org/docs/apache-airflow/2.6.1/installation.html#constraints-files

#This is to help installing dependency locally in IDE

# 2.6.1 was released on January 20, 2023
AIRFLOW_VERSION=2.6.1
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"

# Install airflow core without  installing any extra providers
CONSTRAINT_NO_PROVIDER_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-no-providers-${PYTHON_VERSION}.txt"
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_NO_PROVIDER_URL}"

# Install extra providers
# https://raw.githubusercontent.com/apache/airflow/constraints-2.6.1/constraints-3.10.txt
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
pip install "apache-airflow[ssh]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"















