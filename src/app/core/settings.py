from functools import cached_property, lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class PostgresSettings(BaseSettings):
    SERVER: str
    USER: str
    PASSWORD: str
    DATABASE: str
    PORT: int

    @cached_property
    def async_db(self) -> str:
        return f'postgresql+asyncpg://{self.USER}:{self.PASSWORD}@{self.SERVER}:{self.PORT}/{self.DATABASE}'

    @cached_property
    def sync_db(self) -> str:
        return f'postgresql://{self.USER}:{self.PASSWORD}@{self.SERVER}:{self.PORT}/{self.DATABASE}'

    model_config = SettingsConfigDict(
        env_prefix="POSTGRES_",
    )


class ProjectSettings(BaseSettings):
    NAME: str
    API_V1_STR: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    PINCODE_EXPIRE_MINUTES: int
    DEFAULT_QUERY_LIMIT: int = Field(default=100)
    SUPER_USER_EMAIL: str
    SUPER_USER_PASSWORD: str

    model_config = SettingsConfigDict(
        env_prefix="PROJECT_",
    )


@lru_cache(maxsize=1)
def get_postgres_settings() -> PostgresSettings:
    return PostgresSettings()  # type: ignore


@lru_cache(maxsize=1)
def get_project_settings() -> ProjectSettings:
    return ProjectSettings()  # type: ignore


class QueueSettings(BaseSettings):
    ACCESS_KEY: str
    SECRET_KEY: str
    QUEUE_URL: str

    model_config = SettingsConfigDict(
        env_prefix="YMQ_",
    )


@lru_cache(maxsize=1)
def get_queue_settings() -> QueueSettings:
    return QueueSettings()  # type: ignore
