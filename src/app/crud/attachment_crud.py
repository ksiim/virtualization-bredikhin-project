import uuid
from boto3.exceptions import S3UploadFailedError
from fastapi import UploadFile
from src.utils.s3_client import get_s3_client
import os

BUCKET_NAME = os.getenv("AWS_STORAGE_BUCKET_NAME")


async def upload_file_to_s3(file: UploadFile) -> str:
    s3 = get_s3_client()
    object_key = f"attachments/{uuid.uuid4()}/{file.filename}"

    try:
        s3.upload_fileobj(file.file, BUCKET_NAME, object_key, ExtraArgs={"ContentType": file.content_type})
        return object_key
    except S3UploadFailedError as e:
        raise RuntimeError(f"Не удалось загрузить файл: {e}")


def generate_presigned_url(object_key: str) -> str:
    s3 = get_s3_client()
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET_NAME, "Key": object_key},
            ExpiresIn=3600,
        )
        return url
    except Exception as e:
        raise RuntimeError(f"Ошибка создания ссылки: {e}")
