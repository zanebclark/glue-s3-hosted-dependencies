from pathlib import Path
from typing import TypeAlias, TYPE_CHECKING

import boto3
import click
from botocore.client import BaseClient
from botocore.exceptions import ClientError

if TYPE_CHECKING:
    from mypy_boto3_s3 import S3Client
    from mypy_boto3_ssm import SSMClient
else:
    S3Client: TypeAlias = BaseClient
    SSMClient: TypeAlias = BaseClient


def upload_whls_to_s3(
    aws_region: str,
    s3_bucket: str,
    tgt_dir: str,
    src_dir: Path,
    ssm_parameter_name: str,
) -> None:
    session = boto3.Session(region_name=aws_region)
    s3_client: S3Client = session.client("s3")
    ssm_client: SSMClient = session.client("ssm")

    # Ensure prefix ends with slash if not empty
    if tgt_dir and not tgt_dir.endswith("/"):
        tgt_dir += "/"

    s3_keys: list[str] = []
    # Iterate over files in directory
    for filepath in src_dir.rglob("*.whl"):
        relpath = filepath.relative_to(src_dir)
        if relpath.suffix == ".whl":
            s3_key = tgt_dir + str(relpath)
            s3_keys.append(f"s3://{s3_bucket}/{s3_key}")

            try:
                print(f"Uploading {str(relpath)} to s3://{s3_bucket}/{s3_key}")
                # noinspection PyUnresolvedReferences
                s3_client.upload_file(str(filepath), s3_bucket, s3_key)
                print(f"Uploaded {str(relpath)} successfully.")
            except ClientError as e:
                print(f"Failed to upload {str(relpath)}: {e}")

    print(f"Writing whl paths to SSM parameter store: {ssm_parameter_name}")
    # noinspection PyUnresolvedReferences
    response = ssm_client.put_parameter(
        Name=ssm_parameter_name,
        Value=",".join(s3_keys),
        Type="StringList",
        Overwrite=True,
    )
    print(
        f"whl paths written to SSM parameter store: : {ssm_parameter_name}\n{response}"
    )


@click.command(name="upload_whls_to_s3")
@click.option("--aws-region", required=True, type=str)
@click.option("--s3-bucket", required=True, type=str)
@click.option("--tgt-dir", required=True, type=str)
@click.option(
    "--src-dir",
    required=True,
    type=click.Path(exists=True, file_okay=False, dir_okay=True, path_type=Path),
)
@click.option("--ssm-parameter-name", required=True, type=str)
def main(
    aws_region: str,
    s3_bucket: str,
    tgt_dir: str,
    src_dir: Path,
    ssm_parameter_name: str,
) -> None:
    upload_whls_to_s3(
        aws_region=aws_region,
        s3_bucket=s3_bucket,
        tgt_dir=tgt_dir,
        src_dir=src_dir,
        ssm_parameter_name=ssm_parameter_name,
    )


if __name__ == "__main__":
    main()
