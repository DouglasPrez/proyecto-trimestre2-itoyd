from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Default allows Lambda to start without a .env file; override in production.
    secret_key: str = "sportspace-dev-secret-change-in-production-2026"
    algorithm: str = "HS256"
    access_token_expire_hours: int = 24

    # AWS
    aws_region: str = "us-east-1"
    s3_bucket: str = ""
    s3_voucher_prefix: str = "vouchers"
    # Injected by Lambda env var DYNAMODB_TABLE (set by Terraform compute module)
    dynamodb_table: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
