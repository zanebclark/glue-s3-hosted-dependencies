# upload_whls_to_s3(
#     aws_region="us-west-1",
#     s3_bucket="glue-s3-hosted-dep-dev-scripts20250809060824709800000001",
#     tgt_dir="whl_files",
#     src_dir=Path.cwd() / "wheels",
#     ssm_parameter_name="/glue-s3-hosted-dependencies/additional-python-modules",
# )
from pathlib import Path
from unittest.mock import patch, MagicMock

import boto3
from click.testing import CliRunner
from moto import mock_aws

from upload_whls_to_s3 import main, upload_whls_to_s3


@patch("upload_whls_to_s3.upload_whls_to_s3", return_value=MagicMock())
def test_main(mock_upload_whls_to_s3: MagicMock, tmpdir) -> None:
    runner = CliRunner()
    tmpdir.mkdir("wheels")
    # noinspection PyTypeChecker
    result = runner.invoke(
        main,
        [
            "--aws-region",
            "test-region",
            "--s3-bucket",
            "test-s3-bucket",
            "--tgt-dir",
            "test-target-dir",
            "--src-dir",
            tmpdir / "wheels",
            "--ssm-parameter-name",
            "test-ssm-parameter-name",
        ],
    )
    mock_upload_whls_to_s3.assert_called_once_with(
        aws_region="test-region",
        s3_bucket="test-s3-bucket",
        tgt_dir="test-target-dir",
        src_dir=tmpdir / "wheels",
        ssm_parameter_name="test-ssm-parameter-name",
    )
    assert result.exit_code == 0


@mock_aws
def test_upload_whls_to_s3(tmpdir):
    aws_region = "us-west-1"

    ssm_parameter_name = "test-ssm-parameter-name"
    ssm_client = boto3.client("ssm", region_name=aws_region)
    ssm_client.put_parameter(
        Name=ssm_parameter_name, Value="placeholder,placeholder1", Type="StringList"
    )

    bucket_name = "test-bucket-name"
    s3_client = boto3.client("s3", region_name=aws_region)

    filenames = ["example-1.whl", "example-2.whl", "example-3.whl"]
    tmpdir.mkdir("wheels")
    src_dir = Path(tmpdir) / "wheels"
    tgt_dir = "whl_files"
    for file_name in filenames:
        path = src_dir / file_name
        path.touch()

    s3_client.create_bucket(
        Bucket=bucket_name, CreateBucketConfiguration={"LocationConstraint": aws_region}
    )

    upload_whls_to_s3(
        aws_region=aws_region,
        s3_bucket=bucket_name,
        tgt_dir=tgt_dir,
        src_dir=src_dir,
        ssm_parameter_name=ssm_parameter_name,
    )

    response = ssm_client.get_parameter(Name=ssm_parameter_name)
    param_value = sorted(response["Parameter"]["Value"].split(","))
    expected_param_value = sorted(
        [f"s3://{bucket_name}/{tgt_dir}/{filename}" for filename in filenames]
    )
    assert param_value == expected_param_value

    response = s3_client.list_objects_v2(Bucket=bucket_name)
    assert "Contents" in response
    actual_files = sorted([obj["Key"] for obj in response["Contents"]])
    expected_files = [f"{tgt_dir}/{filename}" for filename in filenames]
    assert actual_files == expected_files
