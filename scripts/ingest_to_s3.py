"""
Ingestão da NYC TLC Trip Record Data para a camada raw do S3.

Baixa arquivos Parquet mensais do dataset público "Yellow Taxi Trip Records"
e sobe para s3://<bucket>/raw/nyc_taxi/year=YYYY/month=MM/.

Uso:
    python scripts/ingest_to_s3.py --bucket meu-bucket --year 2024 --months 1 2 3

Requer as variáveis de ambiente AWS configuradas (AWS_ACCESS_KEY_ID,
AWS_SECRET_ACCESS_KEY) ou um profile configurado via `aws configure`.
"""

import argparse
import logging
import os
import sys
from pathlib import Path

import boto3
import requests
from dotenv import load_dotenv

load_dotenv()  # carrega variáveis do arquivo .env (AWS_*, S3_BUCKET) se existir

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
LOCAL_TMP_DIR = Path("./_tmp_downloads")


def download_month(year: int, month: int) -> Path:
    """Baixa o Parquet de um mês específico da NYC TLC para disco local."""
    filename = f"yellow_tripdata_{year}-{month:02d}.parquet"
    url = f"{BASE_URL}/{filename}"
    LOCAL_TMP_DIR.mkdir(parents=True, exist_ok=True)
    local_path = LOCAL_TMP_DIR / filename

    if local_path.exists():
        logger.info("Já existe localmente, pulando download: %s", local_path)
        return local_path

    logger.info("Baixando %s", url)
    response = requests.get(url, stream=True, timeout=120)
    response.raise_for_status()

    with open(local_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=8 * 1024 * 1024):
            f.write(chunk)

    logger.info("Download concluído: %s (%.1f MB)", local_path, local_path.stat().st_size / 1e6)
    return local_path


def upload_to_s3(local_path: Path, bucket: str, year: int, month: int) -> None:
    """Sobe o arquivo para a camada raw do S3, particionado por ano/mês."""
    s3_key = f"raw/nyc_taxi/year={year}/month={month:02d}/{local_path.name}"
    s3 = boto3.client("s3")
    logger.info("Enviando para s3://%s/%s", bucket, s3_key)
    s3.upload_file(str(local_path), bucket, s3_key)
    logger.info("Upload concluído.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--bucket",
        default=os.getenv("S3_BUCKET"),
        required=os.getenv("S3_BUCKET") is None,
        help="Nome do bucket S3 de destino (padrão: variável de ambiente S3_BUCKET)",
    )
    parser.add_argument("--year", type=int, required=True, help="Ano dos dados (ex: 2024)")
    parser.add_argument(
        "--months", type=int, nargs="+", required=True, help="Meses a baixar (ex: 1 2 3)"
    )
    parser.add_argument(
        "--keep-local", action="store_true", help="Não apagar os arquivos locais após o upload"
    )
    args = parser.parse_args()

    for month in args.months:
        try:
            local_path = download_month(args.year, month)
            upload_to_s3(local_path, args.bucket, args.year, month)
            if not args.keep_local:
                local_path.unlink()
        except Exception:
            logger.exception("Falha ao processar ano=%s mes=%s", args.year, month)
            sys.exit(1)

    logger.info("Ingestão concluída com sucesso para os meses: %s", args.months)


if __name__ == "__main__":
    main()
