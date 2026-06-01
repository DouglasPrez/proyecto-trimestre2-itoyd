from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_hours: int = 24

    # AWS
    aws_region: str = "us-east-1"
    s3_bucket: str = ""
    s3_voucher_prefix: str = "vouchers"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
