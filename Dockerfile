FROM amazon/aws-glue-libs:glue_libs_4.0.0_image_01

# ---------- Build-time args with defaults ----------
ARG aws_region=us-west-1
ARG s3_bucket=my-bucket-name
ARG tgt_dir=whl_files
ARG src_dir=./wheels
ARG ssm_parameter_name=/glue-s3-hosted-dependencies/additional-python-modules

ENV AWS_REGION=${aws_region} \
    S3_BUCKET=${s3_bucket} \
    TGT_DIR=${tgt_dir} \
    SRC_DIR=${src_dir} \
    SSM_PARAMETER_NAME=${ssm_parameter_name}

# Create a working directory
WORKDIR /app

# Create directory for wheels
RUN mkdir -p ${SRC_DIR}

COPY requirements.txt .
COPY upload_whls_to_s3.py .

# Install dependencies and build wheels
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip wheel --no-cache-dir -r requirements.txt -w ${SRC_DIR}

RUN echo python3 ./upload_whls_to_s3.py --aws-region "${AWS_REGION}" --s3-bucket "${S3_BUCKET}" --tgt-dir "${TGT_DIR}" --src-dir "${SRC_DIR}" --ssm-parameter-name "${SSM_PARAMETER_NAME}"
SHELL ["/bin/bash", "-c"]

ENTRYPOINT python3 ./upload_whls_to_s3.py \
    --aws-region "${AWS_REGION}" \
    --s3-bucket "${S3_BUCKET}" \
    --tgt-dir "${TGT_DIR}" \
    --src-dir "${SRC_DIR}" \
    --ssm-parameter-name "${SSM_PARAMETER_NAME}"
