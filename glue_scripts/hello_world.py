from __future__ import annotations
import logging
import sys
import structlog

try:
    IS_GLUE_JOB = True
    # noinspection PyUnresolvedReferences
    from pyspark.context import SparkContext

    # noinspection PyUnresolvedReferences
    from awsglue.utils import getResolvedOptions

    # noinspection PyUnresolvedReferences
    from awsglue.context import GlueContext

    # noinspection PyUnresolvedReferences
    from awsglue.job import Job
except ModuleNotFoundError:
    IS_GLUE_JOB = False

logging.basicConfig(
    format="%(asctime)s : %(filename)s - %(funcName)s : %(lineno)d : %(levelname)s : %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
_logger = logging.getLogger(__name__)
_logger.setLevel(logging.DEBUG)


def main(argument_name: str):
    _logger = structlog.get_logger()
    _logger.info(f"Hello world! argument_name: {argument_name}")


if __name__ == "__main__" and IS_GLUE_JOB:
    ## @params: [JOB_NAME]
    _args = getResolvedOptions(sys.argv, ["JOB_NAME", "argument_name"])

    _sc = SparkContext()
    _glue_context = GlueContext(_sc)
    _job = Job(_glue_context)
    _job.init(_args["JOB_NAME"], _args)
    _spark = _glue_context.spark_session

    main(argument_name=_args["argument_name"])
    _job.commit()
