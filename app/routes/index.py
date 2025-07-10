from aws_lambda_powertools.event_handler.api_gateway import Router
import requests
from aws_lambda_powertools.logging import Logger
import json

logger = Logger()
router = Router()

@router.get("/cep/<cep>")
def get_cep(cep: str):
    logger.info(f"CEP: {cep}")
    url = f"https://viacep.com.br/ws/{cep}/json/"
    response = requests.get(url)
    logger.info(f"Response API CEP: {response.text}")

    if response.status_code == 200:
        return {
            "statusCode": 200,
            "body": json.loads(response.text),
            "headers": { "Content-Type": "application/json" }
        }
    else:
        return {
            "statusCode": 404,
            "body": '{"erro": "CEP não encontrado"}'
        }